# Implementation Plan - OTP Password Reset

This plan implements a custom 6-digit OTP flow for password recovery.

## User Review Required
- **Security Limitation**: In a standard client-side app, updating a password without a Firebase-generated link or recent login is restricted. To fully "Reset and then Auto-Login", we would typically need a backend.
- **Proposed Flow**:
    1. User enters Email.
    2. App sends a random 6-digit OTP via SMTP (App Password).
    3. User enters OTP in a new screen.
    4. If correct, User enters New Password.
    5. **Action**: Since we cannot easily "force" a password reset in Firebase from the client without the user being logged in, I will use the **Firebase Reset Link** method inside the email as the primary secure way, OR if the user insists on OTP, I will explain that for the password update to actually *save* to Firebase, the user will still need to follow the Firebase link.
    6. **Alternative (OTP only)**: I can simulate the reset if the user is already logged in, but for "Forgot Password", we will stick to the SMTP mail containing the OTP and then directing them to a secure reset.
    7. **Refined OTP Plan**: I will implement a screen where the user enters the OTP. If valid, I will use `FirebaseAuth` to send the official reset email *after* OTP validation, OR more simply, I will send the 6-digit code for "Verification" and then navigate to a "Change Password" screen where I'll use a Cloud Function (if available) or simply explain the limitation.
    8. **Decision**: I will implement the OTP generation and verification screen as requested. For the "Change Password" part, I will provide a UI that *leads* to the official reset or a simulated success for this demo.

## Proposed Changes

### 1. Forgot Password Screen (Update)
- Generate a 6-digit random code.
- Send it via SMTP.
- Navigate to `OtpVerificationScreen`.

### 2. OTP Verification Screen
#### [NEW] [otp_verification_screen.dart](file:///C:/Users/chipt/AndroidStudioProjects/Shop/lib/screens/otp_verification_screen.dart)
- Input field for the 6-digit code.
- Timer for resending.
- Validation logic.

### 3. Reset Password Screen
#### [NEW] [reset_password_screen.dart](file:///C:/Users/chipt/AndroidStudioProjects/Shop/lib/screens/reset_password_screen.dart)
- New password and Confirm password fields.
- Logic to update password.

## Verification Plan
- Enter email -> Receive OTP.
- Enter wrong OTP -> Error.
- Enter correct OTP -> Navigate to Reset.
- Reset password -> Redirect to Login.
