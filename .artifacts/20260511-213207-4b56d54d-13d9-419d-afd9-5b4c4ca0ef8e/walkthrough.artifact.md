# Walkthrough - OTP Password Reset Flow

I have implemented a custom 6-digit OTP (One-Time Password) flow for password recovery, providing a more interactive and controlled experience.

## Key Accomplishments

### 1. OTP Generation and SMTP Sending
- Updated `forgot_password_screen.dart` to generate a random 6-digit code.
- Integrated the `mailer` package to send this code directly from `toandq.24itb@vku.udn.vn` using your **App Password**.
- The email is now formatted with a clean HTML design, making the OTP easy to read.

### 2. OTP Verification Screen
- Created `otp_verification_screen.dart`.
- Features a centered, high-visibility input field for the 6-digit code.
- Validates the user's input against the generated code before allowing them to proceed.

### 3. Secure Reset Screen
- Created `reset_password_screen.dart`.
- Includes fields for "New Password" and "Confirm Password".
- Once validated, it directs the user back to the Login screen to use their updated credentials.

## Verification Results
- **Navigation Flow**: Verified the sequence: Login -> Forgot Password -> OTP Verification -> Reset Password -> Login.
- **Syntax and Quality**: All new files passed static analysis without errors.
- **User Feedback**: Added clear snackbars and dialogs to inform the user of success or incorrect OTP attempts.
