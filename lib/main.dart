import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:insaf_somiti/screens/all_members_screen.dart';
import 'package:insaf_somiti/screens/cashbox_screen.dart';
import 'package:insaf_somiti/screens/loan_application_screen.dart';
import 'package:insaf_somiti/screens/profile_entry_screen.dart';
import 'package:insaf_somiti/screens/savings_withdraw_screen.dart';
import 'package:insaf_somiti/screens/transaction_report_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: InsafSomitiApp()));
}



class InsafSomitiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ইনসাফ ক্ষুদ্র ঋণ ও সমবায় সমিতি',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Auth Wrapper to check login status
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          return HomePage(user: snapshot.data!);
        }

        return LoginPage();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.handshake, size: 50, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'ইনসাফ ক্ষুদ্র ঋণ ও\nসমবায় সমিতি',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUp = false; // Toggle between login and signup

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Email and Password Login
  Future<void> _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('ইমেইল এবং পাসওয়ার্ড দিন');
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showErrorDialog('সঠিক ইমেইল ঠিকানা দিন');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save user data to Firestore
      await _saveUserData(userCredential.user!);

      // Navigate to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(user: userCredential.user!)),
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'লগইন ব্যর্থ';
      if (e.code == 'user-not-found') {
        errorMessage = 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'ভুল পাসওয়ার্ড';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'সঠিক ইমেইল ঠিকানা দিন';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('ত্রুটি হয়েছে: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Email and Password Sign Up
  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('ইমেইল এবং পাসওয়ার্ড দিন');
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showErrorDialog('সঠিক ইমেইল ঠিকানা দিন');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorDialog('পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Save user data to Firestore
      await _saveUserData(userCredential.user!);

      _showSuccessDialog('অ্যাকাউন্ট তৈরি সফল! ইমেইল ভেরিফিকেশন পাঠানো হয়েছে।');

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'রেজিস্ট্রেশন ব্যর্থ';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'এই ইমেইল ইতিমধ্যে ব্যবহার করা হয়েছে';
      } else if (e.code == 'weak-password') {
        errorMessage = 'পাসওয়ার্ড আরও শক্তিশালী করুন';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'সঠিক ইমেইল ঠিকানা দিন';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('ত্রুটি হয়েছে: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Forgot Password
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog('ইমেইল ঠিকানা দিন');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showSuccessDialog('পাসওয়ার্ড রিসেট লিঙ্ক আপনার ইমেইলে পাঠানো হয়েছে');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'পাসওয়ার্ড রিসেট ব্যর্থ';
      if (e.code == 'user-not-found') {
        errorMessage = 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('ত্রুটি হয়েছে: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save user data to Firestore
  Future<void> _saveUserData(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'isEmailVerified': user.emailVerified,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('ত্রুটি', style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ঠিক আছে'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('সফল', style: TextStyle(color: Colors.green)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ঠিক আছে'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[50]!,
              Colors.green[100]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 40),
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Icon(Icons.handshake, size: 50, color: Colors.white),
        ),
        SizedBox(height: 20),
        Text(
          'ইনসাফ ক্ষুদ্র ঋণ ও\nসমবায় সমিতি',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.green[900],
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          _isSignUp ? 'নতুন অ্যাকাউন্ট তৈরি করুন' : 'সদস্য লগইন',
          style: TextStyle(
            fontSize: 16,
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'ইমেইল ঠিকানা',
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'পাসওয়ার্ড',
                  hintText: 'আপনার পাসওয়ার্ড দিন',
                  prefixIcon: Icon(Icons.lock, color: Colors.green),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
              ),
              SizedBox(height: 15),

              // Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Remember Me
                  if (!_isSignUp) Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      Text('মনে রাখুন', style: TextStyle(fontSize: 14)),
                    ],
                  ),

                  // Forgot Password
                  if (!_isSignUp) TextButton(
                    onPressed: _resetPassword,
                    child: Text(
                      'পাসওয়ার্ড ভুলে গেছেন?',
                      style: TextStyle(color: Colors.green[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 30),

        // Login/Signup Button
        _buildAuthButton(),
        SizedBox(height: 20),

        // Toggle between Login and Signup
        _buildToggleAuth(),
        SizedBox(height: 10),

        // Contact Info
        _buildFooterLinks(),
      ],
    );
  }

  Widget _buildAuthButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_isSignUp ? _signUpWithEmail : _loginWithEmail),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
        ),
        child: _isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Text(
          _isSignUp ? 'রেজিস্ট্রেশন করুন' : 'লগইন',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildToggleAuth() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'ইতিমধ্যে অ্যাকাউন্ট আছে?' : 'অ্যাকাউন্ট নেই? ',
          style: TextStyle(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isSignUp = !_isSignUp;
              // Clear fields when toggling
              if (_isSignUp) {
                _passwordController.clear();
              }
            });
          },
          child: Text(
            _isSignUp ? 'লগইন করুন' : 'নতুন অ্যাকাউন্ট তৈরি করুন',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      children: [
        Text(
          'সহায়তার জন্য কল করুন: ০১৭XX-XXXXXX',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        SizedBox(height: 10),
        Text(
          'ইমেইল: support@insaf-somiti.com',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }
}

// Home Page

class HomePage extends StatelessWidget {
  final User user;

  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.green,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1B5E20), // Dark green
                      Color(0xFF4CAF50), // Green
                      Color(0xFF81C784), // Light green
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'স্বাগতম',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  user.email?.split('@').first ?? 'সদস্য',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            // User Avatar with online image

                          ],
                        ),
                        SizedBox(height: 10),
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              icon: Icons.person_3_outlined,
                              value: '২৫০+',
                              label: 'সদস্য',
                            ),
                            _buildStatCard(
                              icon: Icons.savings_outlined,
                              value: '৳১৫ লাখ',
                              label: 'সঞ্চয়',
                            ),
                            _buildStatCard(
                              icon: Icons.request_quote_outlined,
                              value: '৳১০ লাখ',
                              label: 'ঋণ',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                onPressed: () {},
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'logout') {
                    FirebaseAuth.instance.signOut();
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person_outline, color: Colors.green),
                        title: Text('প্রোফাইল'),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'settings',
                      child: ListTile(
                        leading: Icon(Icons.settings_outlined, color: Colors.blue),
                        title: Text('সেটিংস'),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'help',
                      child: ListTile(
                        leading: Icon(Icons.help_outline, color: Colors.orange),
                        title: Text('সাহায্য'),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text('লগআউট'),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),

          // Main Content
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome Card with online image
                Container(
                  margin: EdgeInsets.only(bottom: 25),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE8F5E9), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=800&auto=format&fit=crop&q=60',
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withOpacity(0.1),
                        BlendMode.dstATop,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ইনসাফ সমিতি',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'ক্ষুদ্র ঋণ ও সমবায় সমিতি লিমিটেড',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 15),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                'সদস্য নম্বর: #${user.uid.substring(0, 8).toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 15),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: 'https://cdn-icons-png.flaticon.com/512/5256/5256228.png',
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.handshake,
                              color: Colors.green,
                              size: 40,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Actions Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'দ্রুত এক্সেস',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.green[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.green),
                          SizedBox(width: 6),
                          Text(
                            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                            iconUrl: 'https://icon-library.com/images/member-icon-png/member-icon-png-28.jpg',
                            title: 'সদস্য তালিকা',
                            subtitle: 'ব্যবস্থাপনা',
                            color: Color(0xFF2196F3),
                            context: context,
                            index: 0
                        ),
                      ),
                      SizedBox(width: 16,),
                      Expanded(
                        child: _buildFeatureCard(
                            iconUrl: 'https://cdn-icons-png.flaticon.com/512/103/103849.png',
                            title: 'ক্যাশ বক্স',
                            subtitle: 'লেনদেন',
                            color: Color(0xFF4CAF50),
                            context: context,
                            index: 1
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),



                // Bottom Info Card with online image
                Container(
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1551434678-e076c223a692?w=800&auto=format&fit=crop&q=60',
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.7),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.white, size: 30),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              'আপনার তথ্য সম্পূর্ণ নিরাপদ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Text(
                        'আমরা উন্নত এনক্রিপশন প্রযুক্তি ব্যবহার করি যাতে আপনার সকল লেনদেন তথ্য সম্পূর্ণরূপে সুরক্ষিত থাকে।',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'SSL সুরক্ষিত',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label}) {
    return Container(
      padding: EdgeInsets.all(8),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String iconUrl,
    required String title,
    required String subtitle,
    required Color color,
    required BuildContext context,
    required int index,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      elevation: 5,
      child: InkWell(
        onTap: () {
          // Add navigation logic here
          if(index==0){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MemberListScreen()),
            );
          }
          if(index==1){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CashboxScreen()),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.05), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon container
              Container(
                width: 60,
                height: 60,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: CachedNetworkImage(
                  imageUrl: iconUrl,
                  placeholder: (context, url) => CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.category,
                    color: color,
                    size: 24,
                  ),
                  color: color,
                ),
              ),
              SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[800],
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String avatarUrl,
    required String name,
    required String action,
    required String amount,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  color: color,
                  size: 24,
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}