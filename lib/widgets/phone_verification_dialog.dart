import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/community_service.dart';
import '../utils/toast_utils.dart';

class PhoneVerificationDialog extends StatefulWidget {
  final CommunityService communityService;

  const PhoneVerificationDialog({
    Key? key,
    required this.communityService,
  }) : super(key: key);

  @override
  State<PhoneVerificationDialog> createState() => _PhoneVerificationDialogState();
}

class _PhoneVerificationDialogState extends State<PhoneVerificationDialog> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyPhone() async {
    if (_phoneController.text.isEmpty) {
      ToastUtils.showToast('Please enter your phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isVerified = await widget.communityService
          .verifyPhoneNumber(_phoneController.text.trim());

      if (isVerified) {
        if (!mounted) return;
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        if (!mounted) return;
        ToastUtils.showToast(
            'Phone number not found. Please contact church admin.');
      }
    } catch (e) {
      ToastUtils.showToast('Verification failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Phone Verification',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please enter your registered phone number to access the community',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyPhone,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
