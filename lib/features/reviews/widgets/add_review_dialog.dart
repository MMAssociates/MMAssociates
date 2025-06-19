import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mm_associates/features/auth/services/auth_service.dart';
import 'package:mm_associates/features/data/services/firestore_service.dart';

class AddReviewDialog extends StatefulWidget {
  final String venueId;

  const AddReviewDialog({super.key, required this.venueId});

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService(); // To get user name

  double _rating = 3.0; // Default rating
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
       return;
    }
    if (_rating == 0) {
        setState(() => _errorMessage = "Please select a rating (1-5 stars).");
        return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
        setState(() { _errorMessage = "You must be logged in to submit a review."; _isLoading = false; });
        return;
    }
    final userId = currentUser.uid;
    final userData = await _authService.getUserData(userId);
    final userName = userData?['name'] as String? ?? currentUser.email?.split('@')[0] ?? 'Anonymous User';

    try {
      await _firestoreService.addReviewForVenue(
          widget.venueId,
          userId,
          userName,
          _rating,
          _commentController.text.trim());

       if (mounted) {
          Navigator.pop(context, true); // Indicate success
           ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Review submitted successfully!"), backgroundColor: Colors.green),
            );
       }
    } catch (e) {
        if (mounted) {
            setState(() {
              _errorMessage = e.toString().replaceFirst("Exception: ", "");
              _isLoading = false;
            });
        }
    }

  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text('Write a Review'),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        content: SingleChildScrollView(
             child: Form(
               key: _formKey,
               child: ListBody(
                  children: <Widget>[
                     const Text("Rate this venue:"),
                     const SizedBox(height: 8),
                     Center(
                       child: RatingBar.builder(
                         initialRating: _rating,
                         minRating: 1,
                         direction: Axis.horizontal,
                         allowHalfRating: false, // Or true if you prefer
                         itemCount: 5,
                         itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                         itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                         onRatingUpdate: (rating) => setState(() => _rating = rating),
                       ),
                     ),
                    const SizedBox(height: 20),
                     TextFormField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                            labelText: 'Your Comments (Optional)',
                             hintText: 'Share your experience...',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                           ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                     if (_errorMessage != null)
                        Padding(
                           padding: const EdgeInsets.only(top: 15.0),
                           child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                        ),
                  ],
               ),
             ),
           ),
         actions: <Widget>[
           TextButton(
               onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
               child: const Text('Cancel'),
             ),
            TextButton(
               onPressed: _isLoading ? null : _submitReview,
               child: _isLoading
                   ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                   : const Text('Submit'),
             ),
         ],
    );
  }
}