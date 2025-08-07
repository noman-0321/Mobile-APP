// // ignore_for_file: unused_field

// import 'package:flutter/material.dart';
// import 'package:health_monitoring_system/main.dart';

// class PasscodePage extends StatefulWidget {
//   const PasscodePage({super.key});

//   @override
//   State<PasscodePage> createState() => _PasscodePageState();
// }

// class _PasscodePageState extends State<PasscodePage> {
//   final TextEditingController _controller = TextEditingController();
//   late final VoidCallback _listener;

//   @override
//   void initState() {
//     super.initState();
//     _listener = () => mounted ? setState(() {}) : () {};
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _controller.addListener(_listener);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           PinDisplay(controller: _controller),
//           CustomNumPad(
//             controller: _controller,
//             onCompleted: () {
//               if (_controller.text == "2098") {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (ctx) => HomeScreen()),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// class PinDisplay extends StatelessWidget {
//   final TextEditingController controller;
//   final int length;
//   final bool obscure;
//   final double size;
//   final Color filledColor;
//   final Color emptyColor;
//   final TextStyle? digitStyle;

//   const PinDisplay({
//     super.key,
//     required this.controller,
//     this.length = 4,
//     this.obscure = true,
//     this.size = 20.0,
//     this.filledColor = Colors.black54,
//     this.emptyColor = Colors.black12,
//     this.digitStyle,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final digits = controller.text.characters.toList();

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(length, (index) {
//         final hasValue = index < digits.length;
//         final value = hasValue ? digits[index] : '';

//         return Container(
//           width: size,
//           height: size,
//           margin: EdgeInsets.symmetric(horizontal: size * 0.3),
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color:
//                 hasValue
//                     ? (obscure ? filledColor : Colors.transparent)
//                     : emptyColor,
//             border:
//                 obscure
//                     ? null
//                     : Border.all(color: filledColor.withValues(alpha: 0.6)),
//           ),
//           alignment: Alignment.center,
//           child:
//               (!obscure && hasValue)
//                   ? Text(
//                     value,
//                     style:
//                         digitStyle ??
//                         TextStyle(
//                           fontSize: size * 0.8,
//                           color: filledColor,
//                           fontWeight: FontWeight.w500,
//                         ),
//                   )
//                   : null,
//         );
//       }),
//     );
//   }
// }

// class CustomNumPad extends StatelessWidget {
//   final TextEditingController controller;
//   final int maxLength;
//   final VoidCallback? onCompleted;

//   const CustomNumPad({
//     super.key,
//     required this.controller,
//     this.maxLength = 4,
//     this.onCompleted,
//   });

//   void _onKeyTap(BuildContext context, String key) {
//     final currentText = controller.text;

//     if (key == '←') {
//       if (currentText.isNotEmpty) {
//         controller.value = TextEditingValue(
//           text: currentText.substring(0, currentText.length - 1),
//           selection: TextSelection.collapsed(offset: currentText.length - 1),
//         );
//       }
//     } else {
//       if (currentText.length < maxLength) {
//         final newText = currentText + key;
//         controller.value = TextEditingValue(
//           text: newText,
//           selection: TextSelection.collapsed(offset: newText.length),
//         );
//         if (newText.length == maxLength) {
//           onCompleted?.call();
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final keys = [
//       ['1', '2', '3'],
//       ['4', '5', '6'],
//       ['7', '8', '9'],
//       ['', '0', '←'],
//     ];

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children:
//           keys.map((row) {
//             return Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children:
//                   row.map((key) {
//                     return Expanded(
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child:
//                             key.isEmpty
//                                 ? const SizedBox.shrink()
//                                 : Material(
//                                   color: Colors.transparent,
//                                   child: InkWell(
//                                     onTap: () => _onKeyTap(context, key),
//                                     borderRadius: BorderRadius.circular(8),
//                                     splashColor: Colors.grey.withValues(
//                                       alpha: 0.5,
//                                     ),
//                                     highlightColor: Colors.transparent,
//                                     child: AspectRatio(
//                                       aspectRatio: 1,
//                                       child: Center(
//                                         child: Text(
//                                           key,
//                                           style: const TextStyle(
//                                             fontSize: 28,
//                                             color: Colors.black,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                       ),
//                     );
//                   }).toList(),
//             );
//           }).toList(),
//     );
//   }
// }
