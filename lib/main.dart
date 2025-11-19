import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:insaf_somiti/screens/all_members_screen.dart';
import 'package:insaf_somiti/screens/loan_application_screen.dart';
import 'package:insaf_somiti/screens/profile_entry_screen.dart';
import 'package:insaf_somiti/screens/savings_screen.dart';
import 'package:insaf_somiti/screens/transaction_report_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('ইনসাফ সমিতি'),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                FirebaseAuth.instance.signOut();
              } else if (value == 'profile') {
                // Navigate to profile page
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.green),
                      SizedBox(width: 8),
                      Text('প্রোফাইল'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('লগআউট'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'স্বাগতম!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      user.email ?? 'সদস্য',
                      style: TextStyle(fontSize: 16, color: Colors.green[700]),
                    ),
                    if (!user.emailVerified) ...[
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ইমেইল ভেরিফাই করা প্রয়োজন',
                                style: TextStyle(color: Colors.orange[800], fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 30),

              // User Info Card
              Card(
                child: ListTile(
                  leading: Icon(Icons.email, color: Colors.green),
                  title: Text('ইমেইল: ${user.email ?? 'N/A'}'),
                  subtitle: Text(
                    user.emailVerified ? 'ভেরিফাইড' : 'ভেরিফাই করা হয়নি',
                    style: TextStyle(
                      color: user.emailVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),

              // Quick Actions
              Text(
                'দ্রুত এক্সেস:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildActionCard('👥 প্রোফাইল', Icons.person, Colors.purple,context,1),
                    _buildActionCard('💰 ক্যাশ বক্স', Icons.attach_money, Colors.blue,context,2),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color,BuildContext context,int index) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () {
          if(index==2){
            //SavingsEntryScreen
            Navigator.push(context, MaterialPageRoute(builder: (context)=>MemberEntryScreen()));
          }

          // if(index==2){
          //   //SavingsEntryScreen
          //   Navigator.push(context, MaterialPageRoute(builder: (context)=>SavingsEntryScreen()));
          // }
          // if(index==3){
          //   //SavingsEntryScreen
          //   Navigator.push(context, MaterialPageRoute(builder: (context)=>CombinedReportScreen()));
          // }
          if(index==1){
            //SavingsEntryScreen
            Navigator.push(context, MaterialPageRoute(builder: (context)=>MemberListScreen()));
          }

        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}