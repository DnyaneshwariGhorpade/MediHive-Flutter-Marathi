import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MediHive'**
  String get appName;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'MediHive {version}'**
  String appVersion(String version);

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Smart Clinic Management'**
  String get appTagline;

  /// No description provided for @professionalHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Professional Healthcare Management'**
  String get professionalHealthcare;

  /// No description provided for @welcomeToMedihive.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Medihive'**
  String get welcomeToMedihive;

  /// No description provided for @signInToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToYourAccount;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterUsername;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'LOG IN'**
  String get logIn;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN WITH GOOGLE'**
  String get signInWithGoogle;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed'**
  String get googleSignInFailed;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @opd.
  ///
  /// In en, this message translates to:
  /// **'OPD'**
  String get opd;

  /// No description provided for @patients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patients;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @doctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile'**
  String get doctorProfile;

  /// No description provided for @clinicInformation.
  ///
  /// In en, this message translates to:
  /// **'Clinic Information'**
  String get clinicInformation;

  /// No description provided for @dataAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Data & Security'**
  String get dataAndSecurity;

  /// No description provided for @backupAndCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Backup & Cloud Sync'**
  String get backupAndCloudSync;

  /// No description provided for @authentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authentication;

  /// No description provided for @importFromDesktop.
  ///
  /// In en, this message translates to:
  /// **'Import from Desktop'**
  String get importFromDesktop;

  /// No description provided for @googleCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Google Cloud Backup'**
  String get googleCloudBackup;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @healthcareManagementSystem.
  ///
  /// In en, this message translates to:
  /// **'Healthcare Management System'**
  String get healthcareManagementSystem;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get marathi;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @clinicOverview.
  ///
  /// In en, this message translates to:
  /// **'Clinic Overview'**
  String get clinicOverview;

  /// No description provided for @revenueSplit.
  ///
  /// In en, this message translates to:
  /// **'Revenue Split'**
  String get revenueSplit;

  /// No description provided for @recentOpdActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent OPD Activity'**
  String get recentOpdActivity;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @todaysVisits.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Visits'**
  String get todaysVisits;

  /// No description provided for @weeklyVisits.
  ///
  /// In en, this message translates to:
  /// **'Weekly Visits'**
  String get weeklyVisits;

  /// No description provided for @monthlyVisits.
  ///
  /// In en, this message translates to:
  /// **'Monthly Visits'**
  String get monthlyVisits;

  /// No description provided for @followUpsDue.
  ///
  /// In en, this message translates to:
  /// **'Follow-ups Due'**
  String get followUpsDue;

  /// No description provided for @noRecentPatients.
  ///
  /// In en, this message translates to:
  /// **'No recent patients found'**
  String get noRecentPatients;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @days7.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get days7;

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get days30;

  /// No description provided for @months6.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get months6;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @opdQueue.
  ///
  /// In en, this message translates to:
  /// **'OPD Queue'**
  String get opdQueue;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @selectedDate.
  ///
  /// In en, this message translates to:
  /// **'Selected date'**
  String get selectedDate;

  /// No description provided for @noOpdRecordsToday.
  ///
  /// In en, this message translates to:
  /// **'No OPD records found for today.'**
  String get noOpdRecordsToday;

  /// No description provided for @noAppointmentsThisDay.
  ///
  /// In en, this message translates to:
  /// **'No appointments scheduled for this day.'**
  String get noAppointmentsThisDay;

  /// No description provided for @newRegistrationsAppear.
  ///
  /// In en, this message translates to:
  /// **'New registrations will appear here'**
  String get newRegistrationsAppear;

  /// No description provided for @selectDifferentDate.
  ///
  /// In en, this message translates to:
  /// **'Select a different date to view records'**
  String get selectDifferentDate;

  /// No description provided for @registerPatient.
  ///
  /// In en, this message translates to:
  /// **'Register Patient'**
  String get registerPatient;

  /// No description provided for @patientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} patients'**
  String patientsCount(Object count);

  /// No description provided for @patientsCount_one.
  ///
  /// In en, this message translates to:
  /// **'{count} patient'**
  String patientsCount_one(Object count);

  /// No description provided for @consultation.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get consultation;

  /// No description provided for @followUp.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW-UP'**
  String get followUp;

  /// No description provided for @noDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'No diagnosis'**
  String get noDiagnosis;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not Specified'**
  String get notSpecified;

  /// No description provided for @newOpd.
  ///
  /// In en, this message translates to:
  /// **'New OPD'**
  String get newOpd;

  /// No description provided for @opdRegistration.
  ///
  /// In en, this message translates to:
  /// **'OPD Registration'**
  String get opdRegistration;

  /// No description provided for @patientInformation.
  ///
  /// In en, this message translates to:
  /// **'Patient Information'**
  String get patientInformation;

  /// No description provided for @medicalClinicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Medical & Clinical Details'**
  String get medicalClinicalDetails;

  /// No description provided for @billingPayment.
  ///
  /// In en, this message translates to:
  /// **'Billing & Payment'**
  String get billingPayment;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(Object current, Object total);

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter mobile number'**
  String get enterMobileNumber;

  /// No description provided for @mobileRequired.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get mobileRequired;

  /// No description provided for @enterExactly10Digits.
  ///
  /// In en, this message translates to:
  /// **'Enter exactly 10 digits'**
  String get enterExactly10Digits;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterPatientName.
  ///
  /// In en, this message translates to:
  /// **'Enter patient name'**
  String get enterPatientName;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth *'**
  String get dateOfBirth;

  /// No description provided for @tapToSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Tap to select date'**
  String get tapToSelectDate;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @yearsMonths.
  ///
  /// In en, this message translates to:
  /// **'Years/Months'**
  String get yearsMonths;

  /// No description provided for @invalidAge.
  ///
  /// In en, this message translates to:
  /// **'Invalid age'**
  String get invalidAge;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age: {years} years {months} months'**
  String ageLabel(Object months, Object years);

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @enterFullAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter full address'**
  String get enterFullAddress;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @bloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get bloodGroup;

  /// No description provided for @availablePatients.
  ///
  /// In en, this message translates to:
  /// **'Available Patients'**
  String get availablePatients;

  /// No description provided for @registerNewPatient.
  ///
  /// In en, this message translates to:
  /// **'Register New Patient'**
  String get registerNewPatient;

  /// No description provided for @diagnosisLabel.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosisLabel;

  /// No description provided for @searchOrAddDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Search or add diagnosis...'**
  String get searchOrAddDiagnosis;

  /// No description provided for @symptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptoms;

  /// No description provided for @uploadDocumentsOptional.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents (Optional)'**
  String get uploadDocumentsOptional;

  /// No description provided for @tapToUploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload documents'**
  String get tapToUploadDocuments;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded successfully!'**
  String get documentUploaded;

  /// No description provided for @readyForSubmission.
  ///
  /// In en, this message translates to:
  /// **'Ready for submission'**
  String get readyForSubmission;

  /// No description provided for @clinicalNotes.
  ///
  /// In en, this message translates to:
  /// **'Clinical Notes'**
  String get clinicalNotes;

  /// No description provided for @enterObservationsNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter observations and notes'**
  String get enterObservationsNotes;

  /// No description provided for @panchakarmaNotes.
  ///
  /// In en, this message translates to:
  /// **'Panchakarma Notes'**
  String get panchakarmaNotes;

  /// No description provided for @enterPanchakarmaNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter Panchakarma treatment notes'**
  String get enterPanchakarmaNotes;

  /// No description provided for @opdType.
  ///
  /// In en, this message translates to:
  /// **'OPD Type'**
  String get opdType;

  /// No description provided for @previousVisitDate.
  ///
  /// In en, this message translates to:
  /// **'Previous Visit Date'**
  String get previousVisitDate;

  /// No description provided for @followUpReason.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Reason'**
  String get followUpReason;

  /// No description provided for @enterFollowUpReason.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for follow-up...'**
  String get enterFollowUpReason;

  /// No description provided for @prescriptions.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptions;

  /// No description provided for @prescribeMedicine.
  ///
  /// In en, this message translates to:
  /// **'Prescribe Medicine'**
  String get prescribeMedicine;

  /// No description provided for @typeMedicineSearch.
  ///
  /// In en, this message translates to:
  /// **'Type medicine name to search...'**
  String get typeMedicineSearch;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @nextVisitDate.
  ///
  /// In en, this message translates to:
  /// **'Next Visit Date'**
  String get nextVisitDate;

  /// No description provided for @consultationFees.
  ///
  /// In en, this message translates to:
  /// **'Consultation Fees'**
  String get consultationFees;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @mustBeValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Must be a valid number'**
  String get mustBeValidNumber;

  /// No description provided for @medicineFee.
  ///
  /// In en, this message translates to:
  /// **'Medicine Fee'**
  String get medicineFee;

  /// No description provided for @panchakarmaFee.
  ///
  /// In en, this message translates to:
  /// **'Panchakarma Fee'**
  String get panchakarmaFee;

  /// No description provided for @discountType.
  ///
  /// In en, this message translates to:
  /// **'Discount Type'**
  String get discountType;

  /// No description provided for @discountValue.
  ///
  /// In en, this message translates to:
  /// **'Discount Value'**
  String get discountValue;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @paymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get paymentMode;

  /// No description provided for @chargeType.
  ///
  /// In en, this message translates to:
  /// **'Charge Type'**
  String get chargeType;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStep;

  /// No description provided for @saveOpdRecord.
  ///
  /// In en, this message translates to:
  /// **'Save OPD Record'**
  String get saveOpdRecord;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @continueEditing.
  ///
  /// In en, this message translates to:
  /// **'Continue Editing'**
  String get continueEditing;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved successfully'**
  String get draftSaved;

  /// No description provided for @resumingDraft.
  ///
  /// In en, this message translates to:
  /// **'Resuming saved draft'**
  String get resumingDraft;

  /// No description provided for @recordSaved.
  ///
  /// In en, this message translates to:
  /// **'Record Saved!'**
  String get recordSaved;

  /// No description provided for @patientAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Patient added successfully'**
  String get patientAddedSuccessfully;

  /// No description provided for @failedToSaveRecord.
  ///
  /// In en, this message translates to:
  /// **'Failed to save record. Please try again.'**
  String get failedToSaveRecord;

  /// No description provided for @patientManagement.
  ///
  /// In en, this message translates to:
  /// **'Patient Management'**
  String get patientManagement;

  /// No description provided for @noPatientsYet.
  ///
  /// In en, this message translates to:
  /// **'No Patients Yet'**
  String get noPatientsYet;

  /// No description provided for @noPatientsOnDate.
  ///
  /// In en, this message translates to:
  /// **'No Patients on This Date'**
  String get noPatientsOnDate;

  /// No description provided for @addPatientViaOpd.
  ///
  /// In en, this message translates to:
  /// **'Add your first patient via OPD Registration'**
  String get addPatientViaOpd;

  /// No description provided for @patientDetails.
  ///
  /// In en, this message translates to:
  /// **'Patient Details'**
  String get patientDetails;

  /// No description provided for @patientNotFound.
  ///
  /// In en, this message translates to:
  /// **'Patient not found'**
  String get patientNotFound;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirthLabel;

  /// No description provided for @visitHistory.
  ///
  /// In en, this message translates to:
  /// **'Visit History'**
  String get visitHistory;

  /// No description provided for @viewPrescription.
  ///
  /// In en, this message translates to:
  /// **'View Prescription'**
  String get viewPrescription;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @deletePatient.
  ///
  /// In en, this message translates to:
  /// **'Delete Patient'**
  String get deletePatient;

  /// No description provided for @deletePatientConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} and all associated records?'**
  String deletePatientConfirm(Object name);

  /// No description provided for @deleteOpdRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete OPD Record'**
  String get deleteOpdRecord;

  /// No description provided for @deleteOpdConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete OPD record from {date}?'**
  String deleteOpdConfirm(Object date);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @whatsappOpened.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp opened with prescription attached'**
  String get whatsappOpened;

  /// No description provided for @noValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Patient has no valid phone number'**
  String get noValidPhone;

  /// No description provided for @editPatient.
  ///
  /// In en, this message translates to:
  /// **'Edit Patient'**
  String get editPatient;

  /// No description provided for @patientInformationLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient Information'**
  String get patientInformationLabel;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @mobileRequiredEdit.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get mobileRequiredEdit;

  /// No description provided for @enterAtLeast10.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 10 digits'**
  String get enterAtLeast10;

  /// No description provided for @patientUpdated.
  ///
  /// In en, this message translates to:
  /// **'Patient {name} updated'**
  String patientUpdated(Object name);

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSaving(Object error);

  /// No description provided for @prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// No description provided for @medicinesPrescribed.
  ///
  /// In en, this message translates to:
  /// **'Medicines Prescribed'**
  String get medicinesPrescribed;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get medicineName;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @noPanchakarmaNotes.
  ///
  /// In en, this message translates to:
  /// **'No Panchakarma notes'**
  String get noPanchakarmaNotes;

  /// No description provided for @computerGeneratedRx.
  ///
  /// In en, this message translates to:
  /// **'This is a computer-generated prescription'**
  String get computerGeneratedRx;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get addMedicine;

  /// No description provided for @tapEditIcon.
  ///
  /// In en, this message translates to:
  /// **'Tap the edit icon to make changes'**
  String get tapEditIcon;

  /// No description provided for @prescriptionSaved.
  ///
  /// In en, this message translates to:
  /// **'Prescription saved'**
  String get prescriptionSaved;

  /// No description provided for @failedToSavePrescription.
  ///
  /// In en, this message translates to:
  /// **'Failed to save prescription: {error}'**
  String failedToSavePrescription(Object error);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minsAgo.
  ///
  /// In en, this message translates to:
  /// **'{mins} mins ago'**
  String minsAgo(Object mins);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(Object hours);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @developerInformation.
  ///
  /// In en, this message translates to:
  /// **'Developer Information'**
  String get developerInformation;

  /// No description provided for @forTechnicalQueries.
  ///
  /// In en, this message translates to:
  /// **'For Technical queries:'**
  String get forTechnicalQueries;

  /// No description provided for @applicationInfo.
  ///
  /// In en, this message translates to:
  /// **'Application Info'**
  String get applicationInfo;

  /// No description provided for @appNameLabel.
  ///
  /// In en, this message translates to:
  /// **'App Name:'**
  String get appNameLabel;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version:'**
  String get version;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform:'**
  String get platform;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated:'**
  String get lastUpdated;

  /// No description provided for @backupInformation.
  ///
  /// In en, this message translates to:
  /// **'Backup Information'**
  String get backupInformation;

  /// No description provided for @backupFilesStored.
  ///
  /// In en, this message translates to:
  /// **'Backup files are stored locally on your system.'**
  String get backupFilesStored;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @autoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get autoSync;

  /// No description provided for @syncFrequency.
  ///
  /// In en, this message translates to:
  /// **'Sync Frequency'**
  String get syncFrequency;

  /// No description provided for @wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'WiFi Only'**
  String get wifiOnly;

  /// No description provided for @driveUsage.
  ///
  /// In en, this message translates to:
  /// **'Drive Usage'**
  String get driveUsage;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @authenticationTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authenticationTitle;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @importFromDesktopTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Desktop'**
  String get importFromDesktopTitle;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @chatbotTitle.
  ///
  /// In en, this message translates to:
  /// **'MediHive Assistant'**
  String get chatbotTitle;

  /// No description provided for @chatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatPlaceholder;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @verifyUsername.
  ///
  /// In en, this message translates to:
  /// **'Verify Username'**
  String get verifyUsername;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @twoFactorVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Verification'**
  String get twoFactorVerifyTitle;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your verification code'**
  String get enterVerificationCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @useBackupCode.
  ///
  /// In en, this message translates to:
  /// **'Use a backup code instead'**
  String get useBackupCode;

  /// No description provided for @backupCodesRemaining.
  ///
  /// In en, this message translates to:
  /// **'You have {count} backup code(s) remaining'**
  String backupCodesRemaining(Object count);

  /// No description provided for @smartClinicManagement.
  ///
  /// In en, this message translates to:
  /// **'Smart Clinic Management'**
  String get smartClinicManagement;

  /// No description provided for @weeklyLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyLabel;

  /// No description provided for @monthlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyLabel;

  /// No description provided for @yearlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyLabel;

  /// No description provided for @googleDriveSync.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync'**
  String get googleDriveSync;

  /// No description provided for @cloudBackupActive.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup Active'**
  String get cloudBackupActive;

  /// No description provided for @keepDataSecure.
  ///
  /// In en, this message translates to:
  /// **'Keep your clinic data secure'**
  String get keepDataSecure;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connectGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Connect your Google Drive to enable automated cloud backups. This ensures your patient records and OPD records are backed up securely and can be restored at any time.'**
  String get connectGoogleDrive;

  /// No description provided for @connectGoogleDriveForBackup.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Drive for Backup'**
  String get connectGoogleDriveForBackup;

  /// No description provided for @lastSyncTime.
  ///
  /// In en, this message translates to:
  /// **'Last Sync Time'**
  String get lastSyncTime;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @googleDriveConnected.
  ///
  /// In en, this message translates to:
  /// **'Google Drive connected successfully!'**
  String get googleDriveConnected;

  /// No description provided for @backupSynced.
  ///
  /// In en, this message translates to:
  /// **'Backup synchronised successfully!'**
  String get backupSynced;

  /// No description provided for @syncingData.
  ///
  /// In en, this message translates to:
  /// **'Syncing data...'**
  String get syncingData;

  /// No description provided for @connectingToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Google Drive...'**
  String get connectingToGoogleDrive;

  /// No description provided for @googleDriveDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Google Drive disconnected.'**
  String get googleDriveDisconnected;

  /// No description provided for @noPrescriptionRecords.
  ///
  /// In en, this message translates to:
  /// **'No prescription records found'**
  String get noPrescriptionRecords;

  /// No description provided for @failedToLoadPrescription.
  ///
  /// In en, this message translates to:
  /// **'Failed to load prescription: {error}'**
  String failedToLoadPrescription(String error);

  /// No description provided for @errorSavingPrescription.
  ///
  /// In en, this message translates to:
  /// **'Error saving prescription: {error}'**
  String errorSavingPrescription(String error);

  /// No description provided for @errorPrintingPrescription.
  ///
  /// In en, this message translates to:
  /// **'Error printing prescription: {error}'**
  String errorPrintingPrescription(String error);

  /// No description provided for @printLabel.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printLabel;

  /// No description provided for @noNewNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNewNotifications;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @usernameNotFound.
  ///
  /// In en, this message translates to:
  /// **'Username not found'**
  String get usernameNotFound;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 4 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful'**
  String get passwordResetSuccess;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @enterUsernameToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter username to reset password'**
  String get enterUsernameToReset;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @atLeast4Characters.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 4 characters'**
  String get atLeast4Characters;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @enterYourUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterYourUsername;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @invalidBackupCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup code'**
  String get invalidBackupCode;

  /// No description provided for @enterBackupCode.
  ///
  /// In en, this message translates to:
  /// **'Enter backup code'**
  String get enterBackupCode;

  /// No description provided for @enterValidBackupCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid backup code (e.g. ABCD-1234)'**
  String get enterValidBackupCode;

  /// No description provided for @todaysFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Follow-ups'**
  String get todaysFollowUps;

  /// No description provided for @upcomingFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Follow-ups'**
  String get upcomingFollowUps;

  /// No description provided for @noFollowUpsToday.
  ///
  /// In en, this message translates to:
  /// **'No follow-ups today.'**
  String get noFollowUpsToday;

  /// No description provided for @noFollowUpsOnDate.
  ///
  /// In en, this message translates to:
  /// **'No follow-ups on this date.'**
  String get noFollowUpsOnDate;

  /// No description provided for @nScheduled.
  ///
  /// In en, this message translates to:
  /// **'{count} Scheduled'**
  String nScheduled(int count);

  /// No description provided for @noteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get noteAdded;

  /// No description provided for @addClinicalReminders.
  ///
  /// In en, this message translates to:
  /// **'Add clinical reminders, doctor schedule notes...'**
  String get addClinicalReminders;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location:'**
  String get location;

  /// No description provided for @dataAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get dataAndPrivacy;

  /// No description provided for @dataPrivacyDescription.
  ///
  /// In en, this message translates to:
  /// **'All patient data is stored locally on your system. MediHive does not upload or share any data with external servers. Your data remains completely private and secure on your local machine.'**
  String get dataPrivacyDescription;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @backupAndCloudSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Cloud Sync'**
  String get backupAndCloudSyncTitle;

  /// No description provided for @localBackup.
  ///
  /// In en, this message translates to:
  /// **'Local Backup'**
  String get localBackup;

  /// No description provided for @exportAndShareLocally.
  ///
  /// In en, this message translates to:
  /// **'Export & Share patient data locally'**
  String get exportAndShareLocally;

  /// No description provided for @generateExcelDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate a secure Excel file containing all patients, clinical OPD visit logs, and appointment lists. Save it locally or send it directly via messaging apps.'**
  String get generateExcelDescription;

  /// No description provided for @exportToDevice.
  ///
  /// In en, this message translates to:
  /// **'Export to Device'**
  String get exportToDevice;

  /// No description provided for @shareBackupBtn.
  ///
  /// In en, this message translates to:
  /// **'Share Backup'**
  String get shareBackupBtn;

  /// No description provided for @month1Period.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get month1Period;

  /// No description provided for @months3Period.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get months3Period;

  /// No description provided for @months6Period.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get months6Period;

  /// No description provided for @months12Period.
  ///
  /// In en, this message translates to:
  /// **'12 Months'**
  String get months12Period;

  /// No description provided for @completeBackup.
  ///
  /// In en, this message translates to:
  /// **'Complete Backup'**
  String get completeBackup;

  /// No description provided for @cloudBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get cloudBackupTitle;

  /// No description provided for @googleDriveBackupActive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive backup active'**
  String get googleDriveBackupActive;

  /// No description provided for @secureOnGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Secure your clinic data on Google Drive'**
  String get secureOnGoogleDrive;

  /// No description provided for @connectDriveDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Drive to securely upload and sync patients, visit logs, and appointment rosters. Your backups are kept securely on your personal Drive.'**
  String get connectDriveDescription;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @googleAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Google Account'**
  String get googleAccountLabel;

  /// No description provided for @lastSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSyncLabel;

  /// No description provided for @autoSyncBackups.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync Backups'**
  String get autoSyncBackups;

  /// No description provided for @uploadRecordsAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Upload records automatically'**
  String get uploadRecordsAutomatically;

  /// No description provided for @autoSyncFrequency.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync Frequency'**
  String get autoSyncFrequency;

  /// No description provided for @wifiOnlySync.
  ///
  /// In en, this message translates to:
  /// **'WiFi Only Sync'**
  String get wifiOnlySync;

  /// No description provided for @doNotSyncOnCellular.
  ///
  /// In en, this message translates to:
  /// **'Do not sync on cellular networks'**
  String get doNotSyncOnCellular;

  /// No description provided for @dailyBackgroundBackup.
  ///
  /// In en, this message translates to:
  /// **'Daily Background Backup'**
  String get dailyBackgroundBackup;

  /// No description provided for @scheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled at {time}'**
  String scheduledAt(String time);

  /// No description provided for @syncingNRecords.
  ///
  /// In en, this message translates to:
  /// **'Syncing {count} records...'**
  String syncingNRecords(int count);

  /// No description provided for @syncNowBtn.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNowBtn;

  /// No description provided for @uploadToDriveBtn.
  ///
  /// In en, this message translates to:
  /// **'Upload to Drive'**
  String get uploadToDriveBtn;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @backupHistory.
  ///
  /// In en, this message translates to:
  /// **'Backup History'**
  String get backupHistory;

  /// No description provided for @connectDriveToViewHistory.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Drive to view cloud backup history.'**
  String get connectDriveToViewHistory;

  /// No description provided for @fetchingHistory.
  ///
  /// In en, this message translates to:
  /// **'Fetching history from Google Drive...'**
  String get fetchingHistory;

  /// No description provided for @noBackupsInDrive.
  ///
  /// In en, this message translates to:
  /// **'No backups found in Google Drive.'**
  String get noBackupsInDrive;

  /// No description provided for @backupFileSize.
  ///
  /// In en, this message translates to:
  /// **'Backup file ({size})'**
  String backupFileSize(String size);

  /// No description provided for @nRecordsSynced.
  ///
  /// In en, this message translates to:
  /// **'{count} records synced'**
  String nRecordsSynced(int count);

  /// No description provided for @restoreBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackupTitle;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'This will completely replace all your current patient database, OPD registrations, and calendar appointments with the backup data. This action cannot be undone.\n\nDo you want to continue?'**
  String get restoreWarning;

  /// No description provided for @restoreDataBtn.
  ///
  /// In en, this message translates to:
  /// **'Restore Data'**
  String get restoreDataBtn;

  /// No description provided for @downloadingBackup.
  ///
  /// In en, this message translates to:
  /// **'Downloading backup file...'**
  String get downloadingBackup;

  /// No description provided for @restoringNRecords.
  ///
  /// In en, this message translates to:
  /// **'Restoring {count} records...'**
  String restoringNRecords(int count);

  /// No description provided for @restoredNRecords.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} records successfully!'**
  String restoredNRecords(int count);

  /// No description provided for @preparingBackupToShare.
  ///
  /// In en, this message translates to:
  /// **'Preparing backup file to share...'**
  String get preparingBackupToShare;

  /// No description provided for @uploadToDriveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Upload to Drive?'**
  String get uploadToDriveQuestion;

  /// No description provided for @backupSavedUploadPrompt.
  ///
  /// In en, this message translates to:
  /// **'Backup saved locally. Upload to Google Drive as well?'**
  String get backupSavedUploadPrompt;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @backupSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Backup saved locally: {file}'**
  String backupSavedLocally(String file);

  /// No description provided for @generatingBackup.
  ///
  /// In en, this message translates to:
  /// **'Generating {period} backup...'**
  String generatingBackup(String period);

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed: {error}'**
  String shareFailed(String error);

  /// No description provided for @syncedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Synced successfully'**
  String get syncedSuccessfully;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @syncFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Retry?'**
  String get syncFailedRetry;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// No description provided for @failedToFetchDriveUsage.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch Drive usage'**
  String get failedToFetchDriveUsage;

  /// No description provided for @failedToLoadBackupHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load backup history: {error}'**
  String failedToLoadBackupHistory(String error);

  /// No description provided for @failedToConnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect: {error}'**
  String failedToConnect(String error);

  /// No description provided for @failedToDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to disconnect: {error}'**
  String failedToDisconnect(String error);

  /// No description provided for @backupScheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup scheduled at {time}'**
  String backupScheduledAt(String time);

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @updateLoginCredentials.
  ///
  /// In en, this message translates to:
  /// **'Update your login credentials'**
  String get updateLoginCredentials;

  /// No description provided for @enterLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter {label}'**
  String enterLabel(String label);

  /// No description provided for @pleaseEnterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password.'**
  String get pleaseEnterCurrentPassword;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect!'**
  String get currentPasswordIncorrect;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get passwordChangedSuccessfully;

  /// No description provided for @failedToUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password: {error}'**
  String failedToUpdatePassword(String error);

  /// No description provided for @twoFactorAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuthentication;

  /// No description provided for @extraSecurityActive.
  ///
  /// In en, this message translates to:
  /// **'Extra security is active'**
  String get extraSecurityActive;

  /// No description provided for @addExtraSecurityLayer.
  ///
  /// In en, this message translates to:
  /// **'Add extra security layer'**
  String get addExtraSecurityLayer;

  /// No description provided for @enable2FA.
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA'**
  String get enable2FA;

  /// No description provided for @enable2FADescription.
  ///
  /// In en, this message translates to:
  /// **'Enable two-factor authentication to add an extra layer of security to your account. You\'ll need to enter a backup code in addition to your password.'**
  String get enable2FADescription;

  /// No description provided for @saveBackupCodesWarning.
  ///
  /// In en, this message translates to:
  /// **'Save these backup codes now. You will not see them again after this screen. Each code can only be used once.'**
  String get saveBackupCodesWarning;

  /// No description provided for @confirmBackupCode.
  ///
  /// In en, this message translates to:
  /// **'Confirm by entering one of the backup codes above:'**
  String get confirmBackupCode;

  /// No description provided for @verifyAndEnable.
  ///
  /// In en, this message translates to:
  /// **'Verify & Enable'**
  String get verifyAndEnable;

  /// No description provided for @twoFAEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication is enabled. Your account has an extra layer of security.'**
  String get twoFAEnabledDescription;

  /// No description provided for @disable2FABtn.
  ///
  /// In en, this message translates to:
  /// **'Disable 2FA'**
  String get disable2FABtn;

  /// No description provided for @disable2FAWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? Two-factor authentication adds an important layer of security to your account.'**
  String get disable2FAWarning;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @twoFAEnabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'2FA enabled successfully!'**
  String get twoFAEnabledSuccess;

  /// No description provided for @twoFADisabled.
  ///
  /// In en, this message translates to:
  /// **'2FA disabled'**
  String get twoFADisabled;

  /// No description provided for @validBackupCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid backup code (e.g. ABCD-1234)'**
  String get validBackupCodeHint;

  /// No description provided for @invalidCodeEnterAbove.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Enter one of the codes displayed above.'**
  String get invalidCodeEnterAbove;

  /// No description provided for @connectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get connectedAccounts;

  /// No description provided for @manageLinkedServices.
  ///
  /// In en, this message translates to:
  /// **'Manage linked services'**
  String get manageLinkedServices;

  /// No description provided for @connectedViaGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Connected via Google Drive'**
  String get connectedViaGoogleDrive;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @disconnectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnectedLabel;

  /// No description provided for @loginSessions.
  ///
  /// In en, this message translates to:
  /// **'Login Sessions'**
  String get loginSessions;

  /// No description provided for @currentDevice.
  ///
  /// In en, this message translates to:
  /// **'Current Device'**
  String get currentDevice;

  /// No description provided for @sessionActive.
  ///
  /// In en, this message translates to:
  /// **'Session active'**
  String get sessionActive;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @alwaysHereToHelp.
  ///
  /// In en, this message translates to:
  /// **'Always here to help'**
  String get alwaysHereToHelp;

  /// No description provided for @helloAssistant.
  ///
  /// In en, this message translates to:
  /// **'Hello, I am your MediHive AI Assistant'**
  String get helloAssistant;

  /// No description provided for @howCanIHelp.
  ///
  /// In en, this message translates to:
  /// **'How can I help you today?'**
  String get howCanIHelp;

  /// No description provided for @chooseQuestion.
  ///
  /// In en, this message translates to:
  /// **'Choose a question:'**
  String get chooseQuestion;

  /// No description provided for @registerNewPatientPrompt.
  ///
  /// In en, this message translates to:
  /// **'Register New Patient →'**
  String get registerNewPatientPrompt;

  /// No description provided for @openBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Open Backup & Restore →'**
  String get openBackupRestore;

  /// No description provided for @openCalendar.
  ///
  /// In en, this message translates to:
  /// **'Open Calendar →'**
  String get openCalendar;

  /// No description provided for @viewPatientList.
  ///
  /// In en, this message translates to:
  /// **'View Patient List →'**
  String get viewPatientList;

  /// No description provided for @demoAssistantMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'m a demo assistant with predefined answers. Try one of the suggested prompts above, or contact support for more help.'**
  String get demoAssistantMessage;

  /// No description provided for @selectDbFileDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the clinic.db file from your desktop app to import patients, OPD visits, clinic settings, and calendar notes.'**
  String get selectDbFileDescription;

  /// No description provided for @databaseFile.
  ///
  /// In en, this message translates to:
  /// **'Database File'**
  String get databaseFile;

  /// No description provided for @tapToSelectDbFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to select clinic.db file'**
  String get tapToSelectDbFile;

  /// No description provided for @importingData.
  ///
  /// In en, this message translates to:
  /// **'Importing data...'**
  String get importingData;

  /// No description provided for @readingAndWriting.
  ///
  /// In en, this message translates to:
  /// **'Reading clinic.db and writing to MediHive'**
  String get readingAndWriting;

  /// No description provided for @importComplete.
  ///
  /// In en, this message translates to:
  /// **'Import Complete!'**
  String get importComplete;

  /// No description provided for @importedLabel.
  ///
  /// In en, this message translates to:
  /// **'imported'**
  String get importedLabel;

  /// No description provided for @skippedLabel.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get skippedLabel;

  /// No description provided for @opdVisitsLabel.
  ///
  /// In en, this message translates to:
  /// **'OPD Visits'**
  String get opdVisitsLabel;

  /// No description provided for @clinicSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinic Settings'**
  String get clinicSettingsLabel;

  /// No description provided for @calendarNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar Notes'**
  String get calendarNotesLabel;

  /// No description provided for @backToSettings.
  ///
  /// In en, this message translates to:
  /// **'Back to Settings'**
  String get backToSettings;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import Failed'**
  String get importFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @importFailedError.
  ///
  /// In en, this message translates to:
  /// **'Import failed unexpectedly: {error}'**
  String importFailedError(String error);

  /// No description provided for @failedToPickFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick file: {error}'**
  String failedToPickFile(String error);

  /// No description provided for @patientIdAge.
  ///
  /// In en, this message translates to:
  /// **'ID: {id} • Age {age}'**
  String patientIdAge(String id, String age);

  /// No description provided for @visitTime.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String visitTime(String time);

  /// No description provided for @todayPeriod.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayPeriod;

  /// No description provided for @thisWeekPeriod.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeekPeriod;

  /// No description provided for @thisMonthPeriod.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonthPeriod;

  /// No description provided for @periodRevenue.
  ///
  /// In en, this message translates to:
  /// **'{period} Revenue'**
  String periodRevenue(String period);

  /// No description provided for @specialtyDesignation.
  ///
  /// In en, this message translates to:
  /// **'Specialty / Designation'**
  String get specialtyDesignation;

  /// No description provided for @medicalLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Medical License Number'**
  String get medicalLicenseNumber;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @nameAndLicenseRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and License are required!'**
  String get nameAndLicenseRequired;

  /// No description provided for @validEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get validEmailAddress;

  /// No description provided for @validPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get validPhoneNumber;

  /// No description provided for @clinicNameField.
  ///
  /// In en, this message translates to:
  /// **'Clinic Name'**
  String get clinicNameField;

  /// No description provided for @clinicPhoneContact.
  ///
  /// In en, this message translates to:
  /// **'Clinic Phone / Contact'**
  String get clinicPhoneContact;

  /// No description provided for @fullAddressField.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddressField;

  /// No description provided for @workingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHours;

  /// No description provided for @websiteOptional.
  ///
  /// In en, this message translates to:
  /// **'Website (optional)'**
  String get websiteOptional;

  /// No description provided for @clinicNameAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Clinic Name and Address are required!'**
  String get clinicNameAddressRequired;

  /// No description provided for @licenseLabel.
  ///
  /// In en, this message translates to:
  /// **'License: {number}'**
  String licenseLabel(String number);

  /// No description provided for @googleUserFallback.
  ///
  /// In en, this message translates to:
  /// **'Google User'**
  String get googleUserFallback;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{title} updated successfully!'**
  String savedSuccessfully(String title);

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(String error);

  /// No description provided for @googleSignInFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed: {error}'**
  String googleSignInFailedMessage(String error);

  /// No description provided for @syncFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String syncFailedMessage(String error);

  /// No description provided for @disconnectFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to disconnect: {error}'**
  String disconnectFailedMessage(String error);

  /// No description provided for @chatPromptAddPatient.
  ///
  /// In en, this message translates to:
  /// **'How do I add a new patient?'**
  String get chatPromptAddPatient;

  /// No description provided for @chatPromptExportData.
  ///
  /// In en, this message translates to:
  /// **'Export last month\'s data'**
  String get chatPromptExportData;

  /// No description provided for @chatPromptAppointments.
  ///
  /// In en, this message translates to:
  /// **'Show me today\'s appointments'**
  String get chatPromptAppointments;

  /// No description provided for @chatPromptPrescription.
  ///
  /// In en, this message translates to:
  /// **'Help with prescription format'**
  String get chatPromptPrescription;

  /// No description provided for @chatResponseAddPatient.
  ///
  /// In en, this message translates to:
  /// **'To add a new patient:\n\n1. Tap the \"OPD Registration\" button on the Dashboard.\n2. Fill in the patient details: name, age, gender, phone number, and address.\n3. Tap \"Save\" to register the patient.\n\nThe patient will appear in your patient list immediately.'**
  String get chatResponseAddPatient;

  /// No description provided for @chatResponseExport.
  ///
  /// In en, this message translates to:
  /// **'To export last month\'s data:\n\n1. Go to Settings → Backup & Restore.\n2. Tap \"Export to Excel\".\n3. Select the date range for last month.\n4. Choose what to include: Patients, OPD Records, Appointments.\n5. Tap \"Export\" — the file will be saved to your device.\n\nYou can also back up to Google Drive from the same screen.'**
  String get chatResponseExport;

  /// No description provided for @chatResponseAppointments.
  ///
  /// In en, this message translates to:
  /// **'To view today\'s appointments:\n\n1. Tap the \"Calendar\" icon on the Dashboard.\n2. Today\'s date is highlighted — all appointments for today will be listed.\n3. Tap any appointment to view or edit details.\n\nYou can also add new appointments from the Calendar screen.'**
  String get chatResponseAppointments;

  /// No description provided for @chatResponsePrescription.
  ///
  /// In en, this message translates to:
  /// **'A prescription in MediHive includes:\n\n• Patient name, age, gender\n• Diagnosis\n• Medicines with dosage & duration\n• Clinical notes\n• Doctor\'s name, clinic info & license number\n• Consultation & medicine fees\n• Follow-up date (optional)\n\nTo create a prescription: go to Patient Details → tap \"Create Prescription\".\nThe PDF is generated automatically and can be shared via WhatsApp.'**
  String get chatResponsePrescription;

  /// No description provided for @chatOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open →'**
  String get chatOpenAction;

  /// No description provided for @faqBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'How do I backup my data?'**
  String get faqBackupTitle;

  /// No description provided for @faqBackupAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Backup & Cloud Sync and click on \"Generate Backup\" to create a local backup or sync with cloud storage.'**
  String get faqBackupAnswer;

  /// No description provided for @faqExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Can I export patient records?'**
  String get faqExportTitle;

  /// No description provided for @faqExportAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can export patient records as Excel files from the Backup section. Choose the time period and click Complete Backup.'**
  String get faqExportAnswer;

  /// No description provided for @faqShareTitle.
  ///
  /// In en, this message translates to:
  /// **'How do I share prescriptions via WhatsApp?'**
  String get faqShareTitle;

  /// No description provided for @faqShareAnswer.
  ///
  /// In en, this message translates to:
  /// **'Open the prescription screen and click the \"Share via WhatsApp\" button to send the prescription directly to the patient.'**
  String get faqShareAnswer;

  /// No description provided for @faqPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'How to change my password?'**
  String get faqPasswordTitle;

  /// No description provided for @faqPasswordAnswer.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Settings > Authentication and click on \"Change Password\" to update your login credentials.'**
  String get faqPasswordAnswer;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email:'**
  String get emailLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone:'**
  String get phoneLabel;

  /// No description provided for @platformMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile (Android/iOS)'**
  String get platformMobile;

  /// No description provided for @lastUpdatedDate.
  ///
  /// In en, this message translates to:
  /// **'May 2026'**
  String get lastUpdatedDate;

  /// No description provided for @backupStoragePath.
  ///
  /// In en, this message translates to:
  /// **'Internal Storage/MediHive/backup'**
  String get backupStoragePath;

  /// No description provided for @createClinicAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Clinic Account'**
  String get createClinicAccount;

  /// No description provided for @registerClinicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register your clinic to get started'**
  String get registerClinicSubtitle;

  /// No description provided for @clinicNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Clinic name required'**
  String get clinicNameRequired;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// No description provided for @doctorInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Doctor Information'**
  String get doctorInformationSection;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @loginCredentialsSection.
  ///
  /// In en, this message translates to:
  /// **'Login Credentials'**
  String get loginCredentialsSection;

  /// No description provided for @enterUsernamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a username'**
  String get enterUsernamePlaceholder;

  /// No description provided for @atLeast3Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters'**
  String get atLeast3Characters;

  /// No description provided for @enterPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get enterPasswordPlaceholder;

  /// No description provided for @atLeast4CharactersLabel.
  ///
  /// In en, this message translates to:
  /// **'At least 4 characters'**
  String get atLeast4CharactersLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @createClinicBtn.
  ///
  /// In en, this message translates to:
  /// **'CREATE CLINIC'**
  String get createClinicBtn;

  /// No description provided for @alreadyHaveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAccountSignIn;

  /// No description provided for @passwordsDoNotMatchExclaim.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match!'**
  String get passwordsDoNotMatchExclaim;

  /// No description provided for @usernameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Username already exists. Try another.'**
  String get usernameAlreadyExists;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Check your connection.'**
  String get registrationFailed;

  /// No description provided for @newClinicCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New clinic? Create an account'**
  String get newClinicCreateAccount;

  /// No description provided for @appointmentReminders.
  ///
  /// In en, this message translates to:
  /// **'Appointment Reminders'**
  String get appointmentReminders;

  /// No description provided for @appointmentRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders for upcoming appointments'**
  String get appointmentRemindersDesc;

  /// No description provided for @appointmentReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Reminder'**
  String get appointmentReminderTitle;

  /// No description provided for @appointmentReminderBody.
  ///
  /// In en, this message translates to:
  /// **'You have an appointment with {patientName} in 10 minutes'**
  String appointmentReminderBody(String patientName);

  /// No description provided for @pushNotificationsChannel.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotificationsChannel;

  /// No description provided for @pushNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Push notifications from server'**
  String get pushNotificationsDesc;

  /// No description provided for @backupGenFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup generation failed: {error}'**
  String backupGenFailed(String error);

  /// No description provided for @googleDriveUsed.
  ///
  /// In en, this message translates to:
  /// **'Google Drive used: {usage} of your Drive storage'**
  String googleDriveUsed(String usage);

  /// No description provided for @restoreInProgress.
  ///
  /// In en, this message translates to:
  /// **'Restoring Data'**
  String get restoreInProgress;

  /// No description provided for @dailyFrequency.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyFrequency;

  /// No description provided for @weeklyFrequency.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyFrequency;

  /// No description provided for @onEverySave.
  ///
  /// In en, this message translates to:
  /// **'On every save'**
  String get onEverySave;

  /// No description provided for @changeBtn.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeBtn;

  /// No description provided for @neverLabel.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get neverLabel;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown Date'**
  String get unknownDate;

  /// No description provided for @shareBackupText.
  ///
  /// In en, this message translates to:
  /// **'MediHive Backup - Clinic Data Export'**
  String get shareBackupText;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAt(String time);

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String yesterdayAt(String time);

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @enterWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter weight (kg)'**
  String get enterWeight;

  /// No description provided for @invalidWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight (e.g. 72.5)'**
  String get invalidWeight;

  /// Label for email/username input field
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get emailOrUsername;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
