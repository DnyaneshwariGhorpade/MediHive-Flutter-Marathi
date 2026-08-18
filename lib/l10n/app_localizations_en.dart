// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MediHive';

  @override
  String appVersion(String version) {
    return 'MediHive $version';
  }

  @override
  String get appTagline => 'Smart Clinic Management';

  @override
  String get professionalHealthcare => 'Professional Healthcare Management';

  @override
  String get welcomeToMedihive => 'Welcome to Medihive';

  @override
  String get signInToYourAccount => 'Sign in to your account';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get enterUsername => 'Enter your username';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get logIn => 'LOG IN';

  @override
  String get signInWithGoogle => 'SIGN IN WITH GOOGLE';

  @override
  String get googleSignInFailed => 'Google Sign-In failed';

  @override
  String get home => 'Home';

  @override
  String get opd => 'OPD';

  @override
  String get patients => 'Patients';

  @override
  String get calendar => 'Calendar';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get doctorProfile => 'Doctor Profile';

  @override
  String get clinicInformation => 'Clinic Information';

  @override
  String get dataAndSecurity => 'Data & Security';

  @override
  String get backupAndCloudSync => 'Backup & Cloud Sync';

  @override
  String get authentication => 'Authentication';

  @override
  String get importFromDesktop => 'Import from Desktop';

  @override
  String get googleCloudBackup => 'Google Cloud Backup';

  @override
  String get preferences => 'Preferences';

  @override
  String get notifications => 'Notifications';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get support => 'Support';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get healthcareManagementSystem => 'Healthcare Management System';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get marathi => 'Marathi';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get clinicOverview => 'Clinic Overview';

  @override
  String get revenueSplit => 'Revenue Split';

  @override
  String get recentOpdActivity => 'Recent OPD Activity';

  @override
  String get viewAll => 'View All';

  @override
  String get todaysVisits => 'Today\'s Visits';

  @override
  String get weeklyVisits => 'Weekly Visits';

  @override
  String get monthlyVisits => 'Monthly Visits';

  @override
  String get followUpsDue => 'Follow-ups Due';

  @override
  String get noRecentPatients => 'No recent patients found';

  @override
  String get total => 'Total';

  @override
  String get close => 'Close';

  @override
  String get days7 => '7 Days';

  @override
  String get days30 => '30 Days';

  @override
  String get months6 => '6 Months';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get opdQueue => 'OPD Queue';

  @override
  String get today => 'Today';

  @override
  String get selectedDate => 'Selected date';

  @override
  String get noOpdRecordsToday => 'No OPD records found for today.';

  @override
  String get noAppointmentsThisDay => 'No appointments scheduled for this day.';

  @override
  String get newRegistrationsAppear => 'New registrations will appear here';

  @override
  String get selectDifferentDate => 'Select a different date to view records';

  @override
  String get registerPatient => 'Register Patient';

  @override
  String patientsCount(Object count) {
    return '$count patients';
  }

  @override
  String patientsCount_one(Object count) {
    return '$count patient';
  }

  @override
  String get consultation => 'Consultation';

  @override
  String get followUp => 'FOLLOW-UP';

  @override
  String get noDiagnosis => 'No diagnosis';

  @override
  String get unknown => 'Unknown';

  @override
  String get years => 'years';

  @override
  String get notSpecified => 'Not Specified';

  @override
  String get newOpd => 'New OPD';

  @override
  String get opdRegistration => 'OPD Registration';

  @override
  String get patientInformation => 'Patient Information';

  @override
  String get medicalClinicalDetails => 'Medical & Clinical Details';

  @override
  String get billingPayment => 'Billing & Payment';

  @override
  String stepOf(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get enterMobileNumber => 'Enter mobile number';

  @override
  String get mobileRequired => 'Mobile number is required';

  @override
  String get enterExactly10Digits => 'Enter exactly 10 digits';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterPatientName => 'Enter patient name';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get dateOfBirth => 'Date of Birth *';

  @override
  String get tapToSelectDate => 'Tap to select date';

  @override
  String get age => 'Age';

  @override
  String get yearsMonths => 'Years/Months';

  @override
  String get invalidAge => 'Invalid age';

  @override
  String ageLabel(Object months, Object years) {
    return 'Age: $years years $months months';
  }

  @override
  String get gender => 'Gender';

  @override
  String get address => 'Address';

  @override
  String get enterFullAddress => 'Enter full address';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get bloodGroup => 'Blood Group';

  @override
  String get availablePatients => 'Available Patients';

  @override
  String get registerNewPatient => 'Register New Patient';

  @override
  String get diagnosisLabel => 'Diagnosis';

  @override
  String get searchOrAddDiagnosis => 'Search or add diagnosis...';

  @override
  String get symptoms => 'Symptoms';

  @override
  String get uploadDocumentsOptional => 'Upload Documents (Optional)';

  @override
  String get tapToUploadDocuments => 'Tap to upload documents';

  @override
  String get documentUploaded => 'Document uploaded successfully!';

  @override
  String get readyForSubmission => 'Ready for submission';

  @override
  String get clinicalNotes => 'Clinical Notes';

  @override
  String get enterObservationsNotes => 'Enter observations and notes';

  @override
  String get panchakarmaNotes => 'Panchakarma Notes';

  @override
  String get enterPanchakarmaNotes => 'Enter Panchakarma treatment notes';

  @override
  String get opdType => 'OPD Type';

  @override
  String get previousVisitDate => 'Previous Visit Date';

  @override
  String get followUpReason => 'Follow-up Reason';

  @override
  String get enterFollowUpReason => 'Enter reason for follow-up...';

  @override
  String get prescriptions => 'Prescriptions';

  @override
  String get prescribeMedicine => 'Prescribe Medicine';

  @override
  String get typeMedicineSearch => 'Type medicine name to search...';

  @override
  String get dosage => 'Dosage';

  @override
  String get nextVisitDate => 'Next Visit Date';

  @override
  String get consultationFees => 'Consultation Fees';

  @override
  String get required => 'Required';

  @override
  String get mustBeValidNumber => 'Must be a valid number';

  @override
  String get medicineFee => 'Medicine Fee';

  @override
  String get panchakarmaFee => 'Panchakarma Fee';

  @override
  String get discountType => 'Discount Type';

  @override
  String get discountValue => 'Discount Value';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get paymentMode => 'Payment Mode';

  @override
  String get chargeType => 'Charge Type';

  @override
  String get previous => 'Previous';

  @override
  String get nextStep => 'Next Step';

  @override
  String get saveOpdRecord => 'Save OPD Record';

  @override
  String get saveDraft => 'Save Draft';

  @override
  String get discard => 'Discard';

  @override
  String get continueEditing => 'Continue Editing';

  @override
  String get draftSaved => 'Draft saved successfully';

  @override
  String get resumingDraft => 'Resuming saved draft';

  @override
  String get recordSaved => 'Record Saved!';

  @override
  String get patientAddedSuccessfully => 'Patient added successfully';

  @override
  String get failedToSaveRecord => 'Failed to save record. Please try again.';

  @override
  String get patientManagement => 'Patient Management';

  @override
  String get noPatientsYet => 'No Patients Yet';

  @override
  String get noPatientsOnDate => 'No Patients on This Date';

  @override
  String get addPatientViaOpd => 'Add your first patient via OPD Registration';

  @override
  String get patientDetails => 'Patient Details';

  @override
  String get patientNotFound => 'Patient not found';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get dateOfBirthLabel => 'Date of Birth';

  @override
  String get visitHistory => 'Visit History';

  @override
  String get viewPrescription => 'View Prescription';

  @override
  String get share => 'Share';

  @override
  String get deletePatient => 'Delete Patient';

  @override
  String deletePatientConfirm(Object name) {
    return 'Delete $name and all associated records?';
  }

  @override
  String get deleteOpdRecord => 'Delete OPD Record';

  @override
  String deleteOpdConfirm(Object date) {
    return 'Delete OPD record from $date?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get whatsappOpened => 'WhatsApp opened with prescription attached';

  @override
  String get noValidPhone => 'Patient has no valid phone number';

  @override
  String get editPatient => 'Edit Patient';

  @override
  String get patientInformationLabel => 'Patient Information';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get mobileRequiredEdit => 'Mobile number is required';

  @override
  String get enterAtLeast10 => 'Enter at least 10 digits';

  @override
  String patientUpdated(Object name) {
    return 'Patient $name updated';
  }

  @override
  String errorSaving(Object error) {
    return 'Error saving: $error';
  }

  @override
  String get prescription => 'Prescription';

  @override
  String get medicinesPrescribed => 'Medicines Prescribed';

  @override
  String get medicineName => 'Medicine Name';

  @override
  String get instructions => 'Instructions';

  @override
  String get noPanchakarmaNotes => 'No Panchakarma notes';

  @override
  String get computerGeneratedRx => 'This is a computer-generated prescription';

  @override
  String get save => 'Save';

  @override
  String get download => 'Download';

  @override
  String get addMedicine => 'Add Medicine';

  @override
  String get tapEditIcon => 'Tap the edit icon to make changes';

  @override
  String get prescriptionSaved => 'Prescription saved';

  @override
  String failedToSavePrescription(Object error) {
    return 'Failed to save prescription: $error';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get clearAll => 'Clear all';

  @override
  String get justNow => 'Just now';

  @override
  String minsAgo(Object mins) {
    return '$mins mins ago';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours hours ago';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get developerInformation => 'Developer Information';

  @override
  String get forTechnicalQueries => 'For Technical queries:';

  @override
  String get applicationInfo => 'Application Info';

  @override
  String get appNameLabel => 'App Name:';

  @override
  String get version => 'Version:';

  @override
  String get platform => 'Platform:';

  @override
  String get lastUpdated => 'Last Updated:';

  @override
  String get backupInformation => 'Backup Information';

  @override
  String get backupFilesStored =>
      'Backup files are stored locally on your system.';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get autoSync => 'Auto Sync';

  @override
  String get syncFrequency => 'Sync Frequency';

  @override
  String get wifiOnly => 'WiFi Only';

  @override
  String get driveUsage => 'Drive Usage';

  @override
  String get restore => 'Restore';

  @override
  String get authenticationTitle => 'Authentication';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get importFromDesktopTitle => 'Import from Desktop';

  @override
  String get selectFile => 'Select File';

  @override
  String get importData => 'Import Data';

  @override
  String get chatbotTitle => 'MediHive Assistant';

  @override
  String get chatPlaceholder => 'Type a message...';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get verifyUsername => 'Verify Username';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get twoFactorVerifyTitle => 'Two-Factor Verification';

  @override
  String get enterVerificationCode => 'Enter your verification code';

  @override
  String get verify => 'Verify';

  @override
  String get useBackupCode => 'Use a backup code instead';

  @override
  String backupCodesRemaining(Object count) {
    return 'You have $count backup code(s) remaining';
  }

  @override
  String get smartClinicManagement => 'Smart Clinic Management';

  @override
  String get weeklyLabel => 'Weekly';

  @override
  String get monthlyLabel => 'Monthly';

  @override
  String get yearlyLabel => 'Yearly';

  @override
  String get googleDriveSync => 'Google Drive Sync';

  @override
  String get cloudBackupActive => 'Cloud Backup Active';

  @override
  String get keepDataSecure => 'Keep your clinic data secure';

  @override
  String get connected => 'Connected';

  @override
  String get connectGoogleDrive =>
      'Connect your Google Drive to enable automated cloud backups. This ensures your patient records and OPD records are backed up securely and can be restored at any time.';

  @override
  String get connectGoogleDriveForBackup => 'Connect Google Drive for Backup';

  @override
  String get lastSyncTime => 'Last Sync Time';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get googleDriveConnected => 'Google Drive connected successfully!';

  @override
  String get backupSynced => 'Backup synchronised successfully!';

  @override
  String get syncingData => 'Syncing data...';

  @override
  String get connectingToGoogleDrive => 'Connecting to Google Drive...';

  @override
  String get googleDriveDisconnected => 'Google Drive disconnected.';

  @override
  String get noPrescriptionRecords => 'No prescription records found';

  @override
  String failedToLoadPrescription(String error) {
    return 'Failed to load prescription: $error';
  }

  @override
  String errorSavingPrescription(String error) {
    return 'Error saving prescription: $error';
  }

  @override
  String errorPrintingPrescription(String error) {
    return 'Error printing prescription: $error';
  }

  @override
  String get printLabel => 'Print';

  @override
  String get noNewNotifications => 'No new notifications';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get usernameNotFound => 'Username not found';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password must be at least 4 characters';

  @override
  String get passwordResetSuccess => 'Password reset successful';

  @override
  String get setNewPassword => 'Set New Password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get enterUsernameToReset => 'Enter username to reset password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get atLeast4Characters => 'Must be at least 4 characters';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get enterYourUsername => 'Enter your username';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get invalidBackupCode => 'Invalid backup code';

  @override
  String get enterBackupCode => 'Enter backup code';

  @override
  String get enterValidBackupCode =>
      'Enter a valid backup code (e.g. ABCD-1234)';

  @override
  String get todaysFollowUps => 'Today\'s Follow-ups';

  @override
  String get upcomingFollowUps => 'Upcoming Follow-ups';

  @override
  String get noFollowUpsToday => 'No follow-ups today.';

  @override
  String get noFollowUpsOnDate => 'No follow-ups on this date.';

  @override
  String nScheduled(int count) {
    return '$count Scheduled';
  }

  @override
  String get noteAdded => 'Note added';

  @override
  String get addClinicalReminders =>
      'Add clinical reminders, doctor schedule notes...';

  @override
  String get location => 'Location:';

  @override
  String get dataAndPrivacy => 'Data & Privacy';

  @override
  String get dataPrivacyDescription =>
      'All patient data is stored locally on your system. MediHive does not upload or share any data with external servers. Your data remains completely private and secure on your local machine.';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get backupAndCloudSyncTitle => 'Backup & Cloud Sync';

  @override
  String get localBackup => 'Local Backup';

  @override
  String get exportAndShareLocally => 'Export & Share patient data locally';

  @override
  String get generateExcelDescription =>
      'Generate a secure Excel file containing all patients, clinical OPD visit logs, and appointment lists. Save it locally or send it directly via messaging apps.';

  @override
  String get exportToDevice => 'Export to Device';

  @override
  String get shareBackupBtn => 'Share Backup';

  @override
  String get month1Period => '1 Month';

  @override
  String get months3Period => '3 Months';

  @override
  String get months6Period => '6 Months';

  @override
  String get months12Period => '12 Months';

  @override
  String get completeBackup => 'Complete Backup';

  @override
  String get cloudBackupTitle => 'Cloud Backup';

  @override
  String get googleDriveBackupActive => 'Google Drive backup active';

  @override
  String get secureOnGoogleDrive => 'Secure your clinic data on Google Drive';

  @override
  String get connectDriveDescription =>
      'Connect Google Drive to securely upload and sync patients, visit logs, and appointment rosters. Your backups are kept securely on your personal Drive.';

  @override
  String get connecting => 'Connecting...';

  @override
  String get googleAccountLabel => 'Google Account';

  @override
  String get lastSyncLabel => 'Last Sync';

  @override
  String get autoSyncBackups => 'Auto-sync Backups';

  @override
  String get uploadRecordsAutomatically => 'Upload records automatically';

  @override
  String get autoSyncFrequency => 'Auto-sync Frequency';

  @override
  String get wifiOnlySync => 'WiFi Only Sync';

  @override
  String get doNotSyncOnCellular => 'Do not sync on cellular networks';

  @override
  String get dailyBackgroundBackup => 'Daily Background Backup';

  @override
  String scheduledAt(String time) {
    return 'Scheduled at $time';
  }

  @override
  String syncingNRecords(int count) {
    return 'Syncing $count records...';
  }

  @override
  String get syncNowBtn => 'Sync Now';

  @override
  String get uploadToDriveBtn => 'Upload to Drive';

  @override
  String get uploading => 'Uploading...';

  @override
  String get backupHistory => 'Backup History';

  @override
  String get connectDriveToViewHistory =>
      'Connect Google Drive to view cloud backup history.';

  @override
  String get fetchingHistory => 'Fetching history from Google Drive...';

  @override
  String get noBackupsInDrive => 'No backups found in Google Drive.';

  @override
  String backupFileSize(String size) {
    return 'Backup file ($size)';
  }

  @override
  String nRecordsSynced(int count) {
    return '$count records synced';
  }

  @override
  String get restoreBackupTitle => 'Restore Backup';

  @override
  String get restoreWarning =>
      'This will completely replace all your current patient database, OPD registrations, and calendar appointments with the backup data. This action cannot be undone.\n\nDo you want to continue?';

  @override
  String get restoreDataBtn => 'Restore Data';

  @override
  String get downloadingBackup => 'Downloading backup file...';

  @override
  String restoringNRecords(int count) {
    return 'Restoring $count records...';
  }

  @override
  String restoredNRecords(int count) {
    return 'Restored $count records successfully!';
  }

  @override
  String get preparingBackupToShare => 'Preparing backup file to share...';

  @override
  String get uploadToDriveQuestion => 'Upload to Drive?';

  @override
  String get backupSavedUploadPrompt =>
      'Backup saved locally. Upload to Google Drive as well?';

  @override
  String get no => 'No';

  @override
  String get upload => 'Upload';

  @override
  String backupSavedLocally(String file) {
    return 'Backup saved locally: $file';
  }

  @override
  String generatingBackup(String period) {
    return 'Generating $period backup...';
  }

  @override
  String restoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String shareFailed(String error) {
    return 'Share failed: $error';
  }

  @override
  String get syncedSuccessfully => 'Synced successfully';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get syncFailedRetry => 'Sync failed. Retry?';

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get failedToFetchDriveUsage => 'Could not fetch Drive usage';

  @override
  String failedToLoadBackupHistory(String error) {
    return 'Failed to load backup history: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Failed to connect: $error';
  }

  @override
  String failedToDisconnect(String error) {
    return 'Failed to disconnect: $error';
  }

  @override
  String backupScheduledAt(String time) {
    return 'Automatic backup scheduled at $time';
  }

  @override
  String get updatePassword => 'Update Password';

  @override
  String get updateLoginCredentials => 'Update your login credentials';

  @override
  String enterLabel(String label) {
    return 'Enter $label';
  }

  @override
  String get pleaseEnterCurrentPassword =>
      'Please enter your current password.';

  @override
  String get currentPasswordIncorrect => 'Current password is incorrect!';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully!';

  @override
  String failedToUpdatePassword(String error) {
    return 'Failed to update password: $error';
  }

  @override
  String get twoFactorAuthentication => 'Two-Factor Authentication';

  @override
  String get extraSecurityActive => 'Extra security is active';

  @override
  String get addExtraSecurityLayer => 'Add extra security layer';

  @override
  String get enable2FA => 'Enable 2FA';

  @override
  String get enable2FADescription =>
      'Enable two-factor authentication to add an extra layer of security to your account. You\'ll need to enter a backup code in addition to your password.';

  @override
  String get saveBackupCodesWarning =>
      'Save these backup codes now. You will not see them again after this screen. Each code can only be used once.';

  @override
  String get confirmBackupCode =>
      'Confirm by entering one of the backup codes above:';

  @override
  String get verifyAndEnable => 'Verify & Enable';

  @override
  String get twoFAEnabledDescription =>
      'Two-factor authentication is enabled. Your account has an extra layer of security.';

  @override
  String get disable2FABtn => 'Disable 2FA';

  @override
  String get disable2FAWarning =>
      'Are you sure? Two-factor authentication adds an important layer of security to your account.';

  @override
  String get disable => 'Disable';

  @override
  String get twoFAEnabledSuccess => '2FA enabled successfully!';

  @override
  String get twoFADisabled => '2FA disabled';

  @override
  String get validBackupCodeHint =>
      'Enter a valid backup code (e.g. ABCD-1234)';

  @override
  String get invalidCodeEnterAbove =>
      'Invalid code. Enter one of the codes displayed above.';

  @override
  String get connectedAccounts => 'Connected Accounts';

  @override
  String get manageLinkedServices => 'Manage linked services';

  @override
  String get connectedViaGoogleDrive => 'Connected via Google Drive';

  @override
  String get notConnected => 'Not connected';

  @override
  String get disconnectedLabel => 'Disconnected';

  @override
  String get loginSessions => 'Login Sessions';

  @override
  String get currentDevice => 'Current Device';

  @override
  String get sessionActive => 'Session active';

  @override
  String get activeLabel => 'Active';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get alwaysHereToHelp => 'Always here to help';

  @override
  String get helloAssistant => 'Hello, I am your MediHive AI Assistant';

  @override
  String get howCanIHelp => 'How can I help you today?';

  @override
  String get chooseQuestion => 'Choose a question:';

  @override
  String get registerNewPatientPrompt => 'Register New Patient →';

  @override
  String get openBackupRestore => 'Open Backup & Restore →';

  @override
  String get openCalendar => 'Open Calendar →';

  @override
  String get viewPatientList => 'View Patient List →';

  @override
  String get demoAssistantMessage =>
      'I\'m a demo assistant with predefined answers. Try one of the suggested prompts above, or contact support for more help.';

  @override
  String get selectDbFileDescription =>
      'Select the clinic.db file from your desktop app to import patients, OPD visits, clinic settings, and calendar notes.';

  @override
  String get databaseFile => 'Database File';

  @override
  String get tapToSelectDbFile => 'Tap to select clinic.db file';

  @override
  String get importingData => 'Importing data...';

  @override
  String get readingAndWriting => 'Reading clinic.db and writing to MediHive';

  @override
  String get importComplete => 'Import Complete!';

  @override
  String get importedLabel => 'imported';

  @override
  String get skippedLabel => 'skipped';

  @override
  String get opdVisitsLabel => 'OPD Visits';

  @override
  String get clinicSettingsLabel => 'Clinic Settings';

  @override
  String get calendarNotesLabel => 'Calendar Notes';

  @override
  String get backToSettings => 'Back to Settings';

  @override
  String get importFailed => 'Import Failed';

  @override
  String get tryAgain => 'Try Again';

  @override
  String importFailedError(String error) {
    return 'Import failed unexpectedly: $error';
  }

  @override
  String failedToPickFile(String error) {
    return 'Failed to pick file: $error';
  }

  @override
  String patientIdAge(String id, String age) {
    return 'ID: $id • Age $age';
  }

  @override
  String visitTime(String time) {
    return 'Time: $time';
  }

  @override
  String get todayPeriod => 'Today';

  @override
  String get thisWeekPeriod => 'This Week';

  @override
  String get thisMonthPeriod => 'This Month';

  @override
  String periodRevenue(String period) {
    return '$period Revenue';
  }

  @override
  String get specialtyDesignation => 'Specialty / Designation';

  @override
  String get medicalLicenseNumber => 'Medical License Number';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get nameAndLicenseRequired => 'Name and License are required!';

  @override
  String get validEmailAddress => 'Please enter a valid email address.';

  @override
  String get validPhoneNumber => 'Please enter a valid phone number.';

  @override
  String get clinicNameField => 'Clinic Name';

  @override
  String get clinicPhoneContact => 'Clinic Phone / Contact';

  @override
  String get fullAddressField => 'Full Address';

  @override
  String get workingHours => 'Working Hours';

  @override
  String get websiteOptional => 'Website (optional)';

  @override
  String get clinicNameAddressRequired =>
      'Clinic Name and Address are required!';

  @override
  String licenseLabel(String number) {
    return 'License: $number';
  }

  @override
  String get googleUserFallback => 'Google User';

  @override
  String savedSuccessfully(String title) {
    return '$title updated successfully!';
  }

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String googleSignInFailedMessage(String error) {
    return 'Google Sign-In failed: $error';
  }

  @override
  String syncFailedMessage(String error) {
    return 'Sync failed: $error';
  }

  @override
  String disconnectFailedMessage(String error) {
    return 'Failed to disconnect: $error';
  }

  @override
  String get chatPromptAddPatient => 'How do I add a new patient?';

  @override
  String get chatPromptExportData => 'Export last month\'s data';

  @override
  String get chatPromptAppointments => 'Show me today\'s appointments';

  @override
  String get chatPromptPrescription => 'Help with prescription format';

  @override
  String get chatResponseAddPatient =>
      'To add a new patient:\n\n1. Tap the \"OPD Registration\" button on the Dashboard.\n2. Fill in the patient details: name, age, gender, phone number, and address.\n3. Tap \"Save\" to register the patient.\n\nThe patient will appear in your patient list immediately.';

  @override
  String get chatResponseExport =>
      'To export last month\'s data:\n\n1. Go to Settings → Backup & Restore.\n2. Tap \"Export to Excel\".\n3. Select the date range for last month.\n4. Choose what to include: Patients, OPD Records, Appointments.\n5. Tap \"Export\" — the file will be saved to your device.\n\nYou can also back up to Google Drive from the same screen.';

  @override
  String get chatResponseAppointments =>
      'To view today\'s appointments:\n\n1. Tap the \"Calendar\" icon on the Dashboard.\n2. Today\'s date is highlighted — all appointments for today will be listed.\n3. Tap any appointment to view or edit details.\n\nYou can also add new appointments from the Calendar screen.';

  @override
  String get chatResponsePrescription =>
      'A prescription in MediHive includes:\n\n• Patient name, age, gender\n• Diagnosis\n• Medicines with dosage & duration\n• Clinical notes\n• Doctor\'s name, clinic info & license number\n• Consultation & medicine fees\n• Follow-up date (optional)\n\nTo create a prescription: go to Patient Details → tap \"Create Prescription\".\nThe PDF is generated automatically and can be shared via WhatsApp.';

  @override
  String get chatOpenAction => 'Open →';

  @override
  String get faqBackupTitle => 'How do I backup my data?';

  @override
  String get faqBackupAnswer =>
      'Go to Settings > Backup & Cloud Sync and click on \"Generate Backup\" to create a local backup or sync with cloud storage.';

  @override
  String get faqExportTitle => 'Can I export patient records?';

  @override
  String get faqExportAnswer =>
      'Yes, you can export patient records as Excel files from the Backup section. Choose the time period and click Complete Backup.';

  @override
  String get faqShareTitle => 'How do I share prescriptions via WhatsApp?';

  @override
  String get faqShareAnswer =>
      'Open the prescription screen and click the \"Share via WhatsApp\" button to send the prescription directly to the patient.';

  @override
  String get faqPasswordTitle => 'How to change my password?';

  @override
  String get faqPasswordAnswer =>
      'Navigate to Settings > Authentication and click on \"Change Password\" to update your login credentials.';

  @override
  String get emailLabel => 'Email:';

  @override
  String get phoneLabel => 'Phone:';

  @override
  String get platformMobile => 'Mobile (Android/iOS)';

  @override
  String get lastUpdatedDate => 'May 2026';

  @override
  String get backupStoragePath => 'Internal Storage/MediHive/backup';

  @override
  String get createClinicAccount => 'Create Clinic Account';

  @override
  String get registerClinicSubtitle => 'Register your clinic to get started';

  @override
  String get clinicNameRequired => 'Clinic name required';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get addressOptional => 'Address (optional)';

  @override
  String get doctorInformationSection => 'Doctor Information';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get loginCredentialsSection => 'Login Credentials';

  @override
  String get enterUsernamePlaceholder => 'Enter a username';

  @override
  String get atLeast3Characters => 'At least 3 characters';

  @override
  String get enterPasswordPlaceholder => 'Enter a password';

  @override
  String get atLeast4CharactersLabel => 'At least 4 characters';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get createClinicBtn => 'CREATE CLINIC';

  @override
  String get alreadyHaveAccountSignIn => 'Already have an account? Sign In';

  @override
  String get passwordsDoNotMatchExclaim => 'Passwords do not match!';

  @override
  String get usernameAlreadyExists => 'Username already exists. Try another.';

  @override
  String get registrationFailed =>
      'Registration failed. Check your connection.';

  @override
  String get newClinicCreateAccount => 'New clinic? Create an account';

  @override
  String get appointmentReminders => 'Appointment Reminders';

  @override
  String get appointmentRemindersDesc => 'Reminders for upcoming appointments';

  @override
  String get appointmentReminderTitle => 'Appointment Reminder';

  @override
  String appointmentReminderBody(String patientName) {
    return 'You have an appointment with $patientName in 10 minutes';
  }

  @override
  String get pushNotificationsChannel => 'Push Notifications';

  @override
  String get pushNotificationsDesc => 'Push notifications from server';

  @override
  String backupGenFailed(String error) {
    return 'Backup generation failed: $error';
  }

  @override
  String googleDriveUsed(String usage) {
    return 'Google Drive used: $usage of your Drive storage';
  }

  @override
  String get restoreInProgress => 'Restoring Data';

  @override
  String get dailyFrequency => 'Daily';

  @override
  String get weeklyFrequency => 'Weekly';

  @override
  String get onEverySave => 'On every save';

  @override
  String get changeBtn => 'Change';

  @override
  String get neverLabel => 'Never';

  @override
  String get unknownDate => 'Unknown Date';

  @override
  String get shareBackupText => 'MediHive Backup - Clinic Data Export';

  @override
  String todayAt(String time) {
    return 'Today at $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Yesterday at $time';
  }

  @override
  String get weight => 'Weight';

  @override
  String get enterWeight => 'Enter weight (kg)';

  @override
  String get invalidWeight => 'Please enter a valid weight (e.g. 72.5)';

  @override
  String get emailOrUsername => 'Email or username';
}
