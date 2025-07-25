// import 'package:dasdaily/login_page.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// // For Every StatefulWidget, Write this Default Code
// class SignupPage extends StatefulWidget {
//   const SignupPage({super.key});

//   @override
//   State<SignupPage> createState() => _SignupPageState();
// }

// class _SignupPageState extends State<SignupPage> {
//   final _formKey = GlobalKey<FormState>(); //validates whether data is correct or not 
//   final _nameController = TextEditingController(); //TextEditingController() - Lets you get the input text
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();

//   bool _isLoading = false;
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _nameController.dispose(); //Stops listening to name input
//     _emailController.dispose();
//     _passwordController.dispose(); 
//     super.dispose(); //You clean the dishes (your custom code) Then you call your helper (your superclass) to mop the floor (super.dispose())
//   }

//   Future<void> _signup() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//         );

//         if (!mounted) return; //Widget is gone (don’t touch the UI!)

//         ScaffoldMessenger.of( //ScaffoldMessenger.of(context) - This finds the part of the screen (Scaffold) where you can show snackbars
//           context,
//         ).showSnackBar(const SnackBar(content: Text("Account created!")));

//         Navigator.pushReplacement( //pushReplacement - Take the user to the login screen, and don’t let them go back to signup
//           context,
//           MaterialPageRoute(builder: (context) => const LoginPage()), //If no data is changing when building this widget, I can make it constant.
//         );

//       } on FirebaseAuthException catch (e) {
//         String message = "Signup failed: ${e.code}";
//         print(e); // prints full FirebaseAuthException

//         if (e.code == 'email-already-in-use') {
//           message = "This email is already in use";
//         } else if (e.code == 'invalid-email') {
//           message = "Invalid email address";
//         } else if (e.code == 'weak-password') {
//           message = "Password is too weak";
//         }

//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(message)));

//       } finally {
//         if (mounted) { //Widget is still on screen (safe to update UI)
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeColor = const Color(0xFF82B29A); // soft sage green

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5), // soft off-white
//       body: SafeArea( //SafeArea ensures that your content: doesn’t overlap with things like the notch, status bar, or bottom navigation bar.
//         child: Center(
//           child: SingleChildScrollView( //This allows the whole screen to scroll up and down if needed.
//             padding: const EdgeInsets.symmetric(horizontal: 30),
//             child: Column( //Column stacks widgets vertically (one on top of another).
//               mainAxisAlignment: MainAxisAlignment.center, //This tries to center everything vertically inside the available space (within the scroll view).
//               children: [
//                 const Text(
//                   "Welcome to DasDaily 🍱",
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF3B3B3B),
//                   ),
//                 ),

//                 const SizedBox(height: 10),

//                 const Text(
//                   "Sign up to get your daily tiffin!",
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),

//                 const SizedBox(height: 30),
                
//                 Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       _buildTextField(
//                         controller: _nameController,
//                         label: "Name",
//                         icon: Icons.person,
//                         validator:
//                             (value) => //We use value! here to force it to not be null (because value is String?, a nullable type).
//                                 value!.isEmpty ? "Enter your name" : null, //checks if the input is empty. If yes → show error: "Enter your name".
//                         autofillHint: AutofillHints.name, //gives the system a hint to autofill this field (like Google autofill).
//                       ),

//                       const SizedBox(height: 20),

//                       _buildTextField(
//                         controller: _emailController,
//                         label: "Email",
//                         icon: Icons.email,
//                         validator:
//                             (value) =>
//                                 value!.isEmpty ? "Enter your email" : null,
//                         autofillHint: AutofillHints.email,
//                       ),

//                       const SizedBox(height: 20),

//                       _buildTextField(
//                         controller: _passwordController,
//                         label: "Password",
//                         icon: Icons.lock,
//                         obscureText: _obscurePassword,
//                         validator: //The validator in a TextFormField is a function that checks the input value and returns an error message 
//                             (value) =>
//                                 value!.length < 6
//                                     ? "Password must be at least 6 characters"
//                                     : null,
//                         autofillHint: AutofillHints.newPassword,

//                         suffixIcon: IconButton( //suffixIcon is a widget (usually an icon) that appears at the end (right side) of a TextFormField.
//                           icon: Icon(
//                             _obscurePassword
//                                 ? Icons.visibility_off
//                                 : Icons.visibility,
//                           ),
//                           onPressed: () { //You use it whenever you want something to happen on tap
//                             setState(() {
//                               _obscurePassword = !_obscurePassword;
//                             });
//                           },
//                         ),
//                       ),

//                       const SizedBox(height: 30),

//                       SizedBox(
//                         width: double.infinity, //the button will stretch to take the full width available
//                         height: 50,
//                         child: ElevatedButton(
//                           onPressed: _isLoading ? null : _signup, //If _isLoading is true, button is disabled (because null = not clickable).
//                           //If not loading, tapping the button calls the _signup() function.
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: themeColor,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           child:
//                               _isLoading
//                                   ? const CircularProgressIndicator(
//                                     valueColor: AlwaysStoppedAnimation<Color>(
//                                       Colors.white,
//                                     ),
//                                   )
//                                   : const Text(
//                                     "Sign Up",
//                                     style: TextStyle(fontSize: 18),
//                                   ),
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       TextButton(
//                         onPressed: () {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const LoginPage(),
//                             ),
//                           );
//                         },
//                         child: const Text(
//                           "Already have an account? Log in",
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     String? Function(String?)? validator,
//     bool obscureText = false,
//     String? autofillHint,
//     Widget? suffixIcon,
//   }) {
//     return TextFormField(
//       controller: controller,
//       validator: validator,
//       obscureText: obscureText,
//       autofillHints: autofillHint != null ? [autofillHint] : null,
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon),
//         suffixIcon: suffixIcon,
//         labelText: label,
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 20,
//           vertical: 18,
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//       ),
//     );
//   }
// }


import 'package:dasdaily/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// For Every StatefulWidget, Write this Default Code
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>(); //validates whether data is correct or not 
  final _nameController = TextEditingController(); //TextEditingController() - Lets you get the input text
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose(); //Stops listening to name input
    _emailController.dispose();
    _passwordController.dispose(); 
    _animationController.dispose();
    super.dispose(); //You clean the dishes (your custom code) Then you call your helper (your superclass) to mop the floor (super.dispose())
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return; //Widget is gone (don't touch the UI!)

        ScaffoldMessenger.of( //ScaffoldMessenger.of(context) - This finds the part of the screen (Scaffold) where you can show snackbars
          context,
        ).showSnackBar(
          SnackBar(
            content: const Text("Account created!", style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF82B29A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            behavior: SnackBarBehavior.floating,
          )
        );

        Navigator.pushReplacement( //pushReplacement - Take the user to the login screen, and don't let them go back to signup
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()), //If no data is changing when building this widget, I can make it constant.
        );

      } on FirebaseAuthException catch (e) {
        String message = "Signup failed: ${e.code}";
        print(e); // prints full FirebaseAuthException

        if (e.code == 'email-already-in-use') {
          message = "This email is already in use";
        } else if (e.code == 'invalid-email') {
          message = "Invalid email address";
        } else if (e.code == 'weak-password') {
          message = "Password is too weak";
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade400,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            behavior: SnackBarBehavior.floating,
          )
        );

      } finally {
        if (mounted) { //Widget is still on screen (safe to update UI)
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF82B29A); // soft sage green

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // slightly cooler off-white
      body: SafeArea( //SafeArea ensures that your content: doesn't overlap with things like the notch, status bar, or bottom navigation bar.
        child: Center(
          child: SingleChildScrollView( //This allows the whole screen to scroll up and down if needed.
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column( //Column stacks widgets vertically (one on top of another).
                  mainAxisAlignment: MainAxisAlignment.center, //This tries to center everything vertically inside the available space (within the scroll view).
                  children: [
                    // Logo/Icon Container with subtle shadow
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [themeColor, themeColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Welcome to DasDaily",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3436),
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Sign up to get your daily tiffin! 🍱",
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 30),
                    
                    // Form Container with subtle elevation
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: "Name",
                              icon: Icons.person_outline,
                              validator:
                                  (value) => //We use value! here to force it to not be null (because value is String?, a nullable type).
                                      value!.isEmpty ? "Enter your name" : null, //checks if the input is empty. If yes → show error: "Enter your name".
                              autofillHint: AutofillHints.name, //gives the system a hint to autofill this field (like Google autofill).
                            ),

                            const SizedBox(height: 20),

                            _buildTextField(
                              controller: _emailController,
                              label: "Email",
                              icon: Icons.email_outlined,
                              validator:
                                  (value) =>
                                      value!.isEmpty ? "Enter your email" : null,
                              autofillHint: AutofillHints.email,
                            ),

                            const SizedBox(height: 20),

                            _buildTextField(
                              controller: _passwordController,
                              label: "Password",
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              validator: //The validator in a TextFormField is a function that checks the input value and returns an error message 
                                  (value) =>
                                      value!.length < 6
                                          ? "Password must be at least 6 characters"
                                          : null,
                              autofillHint: AutofillHints.newPassword,

                              suffixIcon: IconButton( //suffixIcon is a widget (usually an icon) that appears at the end (right side) of a TextFormField.
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () { //You use it whenever you want something to happen on tap
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 30),

                            Container(
                              width: double.infinity, //the button will stretch to take the full width available
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [themeColor, themeColor.withOpacity(0.9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: themeColor.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signup, //If _isLoading is true, button is disabled (because null = not clickable).
                                //If not loading, tapping the button calls the _signup() function.
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                          "Sign Up",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                          children: [
                            const TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Log in",
                              style: TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    String? autofillHint,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        autofillHints: autofillHint != null ? [autofillHint] : null,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3436),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.grey.shade600,
            size: 22,
          ),
          suffixIcon: suffixIcon,
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: const Color(0xFFFAFBFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF82B29A),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}