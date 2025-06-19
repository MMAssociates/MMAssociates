import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add intl package to pubspec.yaml for date formatting

class ReviewListItem extends StatelessWidget {
  final Map<String, dynamic> reviewData;

  const ReviewListItem({super.key, required this.reviewData});

  @override
  Widget build(BuildContext context) {
     final String userName = reviewData['userName'] as String? ?? 'Anonymous';
     final double rating = (reviewData['rating'] as num?)?.toDouble() ?? 0.0;
     final String comment = reviewData['comment'] as String? ?? '';
     final Timestamp? timestamp = reviewData['createdAt'] as Timestamp?;
     final String dateString = timestamp != null
        ? DateFormat('dd MMM yyyy').format(timestamp.toDate()) // Format date
        : 'Unknown date';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Expanded(
                  child: Text(
                     userName,
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                     overflow: TextOverflow.ellipsis,
                   ),
                ),
                 Text(dateString, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
             ],
           ),
          const SizedBox(height: 4),
           IgnorePointer( // Makes the rating bar non-interactive
              child: RatingBar.builder(
                initialRating: rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 18.0, // Smaller stars for display
                itemPadding: const EdgeInsets.symmetric(horizontal: 0.5),
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {}, // Required but unused
              ),
           ),
           if (comment.isNotEmpty) ...[
               const SizedBox(height: 6),
               Text(comment, style: const TextStyle(fontSize: 14, height: 1.3)),
            ],
        ],
      ),
    );
  }
}