import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// App name shown in the login header
  ///
  /// In en, this message translates to:
  /// **'Build4All'**
  String get appTitle;

  /// Generic login title (not role-specific)
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInGeneralTitle;

  /// Validation: invalid email format
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get errEmailInvalid;

  /// Validation: empty email
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get errEmailRequired;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get lblEmail;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get hintEmail;

  /// Generic subtitle under the login title
  ///
  /// In en, this message translates to:
  /// **'Enter your details to continue'**
  String get signInGeneralSubtitle;

  /// Legal notice under the form
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms & Privacy Policy'**
  String get termsNotice;

  /// Generic identifier label
  ///
  /// In en, this message translates to:
  /// **'Email / Username'**
  String get lblIdentifier;

  /// Generic identifier hint
  ///
  /// In en, this message translates to:
  /// **'you@example.com or +961xxxxxxxx or username'**
  String get hintIdentifier;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get lblPassword;

  /// Password hint text
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get hintPassword;

  /// Remember me checkbox label
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// Forgot password action link
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Primary sign-in button label
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get btnSignIn;

  /// Text before the Sign Up link
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Sign up action link
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Validation: empty identifier
  ///
  /// In en, this message translates to:
  /// **'Identifier is required'**
  String get errIdentifierRequired;

  /// Validation: empty password
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get errPasswordRequired;

  /// Validation: password too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errPasswordMin;

  /// Accessibility label for toggling password visibility (show)
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPasswordLabel;

  /// Accessibility label for toggling password visibility (hide)
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePasswordLabel;

  /// No description provided for @nav_super_admin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get nav_super_admin;

  /// No description provided for @nav_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get nav_dashboard;

  /// No description provided for @nav_themes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get nav_themes;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @dashboard_title.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get dashboard_title;

  /// No description provided for @dashboard_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Build4All Manager'**
  String get dashboard_welcome;

  /// No description provided for @dashboard_hint.
  ///
  /// In en, this message translates to:
  /// **'Use the navigation on the left to manage themes and your profile.'**
  String get dashboard_hint;

  /// No description provided for @themes_title.
  ///
  /// In en, this message translates to:
  /// **'Theme Management'**
  String get themes_title;

  /// No description provided for @themes_add.
  ///
  /// In en, this message translates to:
  /// **'Add Theme'**
  String get themes_add;

  /// No description provided for @themes_name.
  ///
  /// In en, this message translates to:
  /// **'Theme Name'**
  String get themes_name;

  /// No description provided for @themes_menuType.
  ///
  /// In en, this message translates to:
  /// **'Menu Type'**
  String get themes_menuType;

  /// No description provided for @themes_setActive.
  ///
  /// In en, this message translates to:
  /// **'Set Active'**
  String get themes_setActive;

  /// No description provided for @themes_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get themes_active;

  /// No description provided for @themes_deactivate_all.
  ///
  /// In en, this message translates to:
  /// **'Deactivate All Themes'**
  String get themes_deactivate_all;

  /// No description provided for @themes_empty.
  ///
  /// In en, this message translates to:
  /// **'No themes yet. Create one.'**
  String get themes_empty;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profile_title;

  /// No description provided for @profile_firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get profile_firstName;

  /// No description provided for @profile_lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get profile_lastName;

  /// No description provided for @profile_username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profile_username;

  /// No description provided for @profile_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profile_email;

  /// No description provided for @profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profile_updated;

  /// No description provided for @profile_changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profile_changePassword;

  /// No description provided for @profile_currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get profile_currentPassword;

  /// No description provided for @profile_newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get profile_newPassword;

  /// No description provided for @profile_updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get profile_updatePassword;

  /// No description provided for @password_updated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully.'**
  String get password_updated;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @dash_total_projects.
  ///
  /// In en, this message translates to:
  /// **'Total Projects'**
  String get dash_total_projects;

  /// No description provided for @dash_active_projects.
  ///
  /// In en, this message translates to:
  /// **'Active Projects'**
  String get dash_active_projects;

  /// No description provided for @dash_inactive_projects.
  ///
  /// In en, this message translates to:
  /// **'Inactive Projects'**
  String get dash_inactive_projects;

  /// No description provided for @dash_recent_projects.
  ///
  /// In en, this message translates to:
  /// **'Recent Projects'**
  String get dash_recent_projects;

  /// No description provided for @dash_no_recent.
  ///
  /// In en, this message translates to:
  /// **'No recent projects yet.'**
  String get dash_no_recent;

  /// No description provided for @dash_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Build4All Manager'**
  String get dash_welcome;

  /// No description provided for @themes_confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete this theme? This cannot be undone.'**
  String get themes_confirm_delete;

  /// No description provided for @themes_colors_section.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get themes_colors_section;

  /// No description provided for @err_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get err_required;

  /// No description provided for @common_more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get common_more;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @profile_details.
  ///
  /// In en, this message translates to:
  /// **'Profile details'**
  String get profile_details;

  /// No description provided for @profile_first_name.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get profile_first_name;

  /// No description provided for @profile_first_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get profile_first_name_hint;

  /// No description provided for @profile_last_name.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get profile_last_name;

  /// No description provided for @profile_last_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get profile_last_name_hint;

  /// No description provided for @profile_username_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get profile_username_hint;

  /// No description provided for @profile_email_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get profile_email_hint;

  /// No description provided for @profile_save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profile_save_changes;

  /// No description provided for @profile_change_password.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profile_change_password;

  /// No description provided for @profile_current_password.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profile_current_password;

  /// No description provided for @profile_new_password.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get profile_new_password;

  /// No description provided for @profile_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get profile_confirm_password;

  /// No description provided for @profile_password_updated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get profile_password_updated;

  /// No description provided for @profile_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Update your password to keep your account secure.'**
  String get profile_password_hint;

  /// No description provided for @profile_update_password.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get profile_update_password;

  /// No description provided for @profile_update_notifications.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get profile_update_notifications;

  /// No description provided for @profile_notify_items.
  ///
  /// In en, this message translates to:
  /// **'Item updates'**
  String get profile_notify_items;

  /// No description provided for @profile_notify_items_sub.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications when businesses update their items'**
  String get profile_notify_items_sub;

  /// No description provided for @profile_notify_feedback.
  ///
  /// In en, this message translates to:
  /// **'User feedback'**
  String get profile_notify_feedback;

  /// No description provided for @profile_notify_feedback_sub.
  ///
  /// In en, this message translates to:
  /// **'Get notified when users submit new feedback'**
  String get profile_notify_feedback_sub;

  /// No description provided for @common_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get common_security;

  /// No description provided for @common_sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get common_sign_out;

  /// No description provided for @common_sign_out_hint.
  ///
  /// In en, this message translates to:
  /// **'You’ll need to sign in again to access the dashboard.'**
  String get common_sign_out_hint;

  /// No description provided for @common_sign_out_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get common_sign_out_confirm;

  /// No description provided for @common_signed_out.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully.'**
  String get common_signed_out;

  /// No description provided for @err_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get err_email;

  /// No description provided for @errPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errPasswordMismatch;

  /// No description provided for @err_unknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get err_unknown;

  /// No description provided for @signUpOwnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner Sign Up'**
  String get signUpOwnerTitle;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @lblUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get lblUsername;

  /// No description provided for @hintUsername.
  ///
  /// In en, this message translates to:
  /// **'your.unique.name'**
  String get hintUsername;

  /// No description provided for @lblFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get lblFirstName;

  /// No description provided for @hintFirstName.
  ///
  /// In en, this message translates to:
  /// **'John'**
  String get hintFirstName;

  /// No description provided for @lblLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lblLastName;

  /// No description provided for @hintLastName.
  ///
  /// In en, this message translates to:
  /// **'Doe'**
  String get hintLastName;

  /// No description provided for @btnSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get btnSendCode;

  /// No description provided for @btnVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get btnVerify;

  /// No description provided for @btnCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get btnCreateAccount;

  /// No description provided for @errCodeSixDigits.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get errCodeSixDigits;

  /// No description provided for @errUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get errUsernameRequired;

  /// No description provided for @errFirstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get errFirstNameRequired;

  /// No description provided for @errLastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get errLastNameRequired;

  /// No description provided for @msgCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent'**
  String get msgCodeSent;

  /// No description provided for @msgWeWillSendCodeEmail.
  ///
  /// In en, this message translates to:
  /// **'We will send a 6-digit code to your email.'**
  String get msgWeWillSendCodeEmail;

  /// No description provided for @msgEnterCodeForEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email}'**
  String msgEnterCodeForEmail(Object email);

  /// No description provided for @msgOwnerRegistered.
  ///
  /// In en, this message translates to:
  /// **'Owner registered successfully'**
  String get msgOwnerRegistered;

  /// No description provided for @owner_nav_title.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner_nav_title;

  /// No description provided for @owner_nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get owner_nav_home;

  /// No description provided for @owner_nav_projects.
  ///
  /// In en, this message translates to:
  /// **'My Apps'**
  String get owner_nav_projects;

  /// No description provided for @owner_nav_requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get owner_nav_requests;

  /// No description provided for @owner_nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get owner_nav_profile;

  /// No description provided for @owner_home_title.
  ///
  /// In en, this message translates to:
  /// **'Owner Home'**
  String get owner_home_title;

  /// No description provided for @owner_projects_title.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get owner_projects_title;

  /// No description provided for @owner_requests_title.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get owner_requests_title;

  /// No description provided for @owner_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Owner Profile'**
  String get owner_profile_title;

  /// No description provided for @owner_home_hello.
  ///
  /// In en, this message translates to:
  /// **'👋Hi,  '**
  String get owner_home_hello;

  /// No description provided for @owner_home_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to launch your next app build?'**
  String get owner_home_subtitle;

  /// No description provided for @owner_home_requestApp.
  ///
  /// In en, this message translates to:
  /// **'Request My App'**
  String get owner_home_requestApp;

  /// No description provided for @owner_home_myProjects.
  ///
  /// In en, this message translates to:
  /// **'My Active Projects'**
  String get owner_home_myProjects;

  /// No description provided for @owner_home_recentRequests.
  ///
  /// In en, this message translates to:
  /// **'Recent requests'**
  String get owner_home_recentRequests;

  /// No description provided for @owner_home_noRecent.
  ///
  /// In en, this message translates to:
  /// **'No recent requests'**
  String get owner_home_noRecent;

  /// No description provided for @owner_home_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get owner_home_viewAll;

  /// No description provided for @tutorial_step1_title.
  ///
  /// In en, this message translates to:
  /// **'Request your app'**
  String get tutorial_step1_title;

  /// No description provided for @tutorial_step1_body.
  ///
  /// In en, this message translates to:
  /// **'Pick a project, name your app, add notes, and submit the request.'**
  String get tutorial_step1_body;

  /// No description provided for @tutorial_step2_title.
  ///
  /// In en, this message translates to:
  /// **'Track approval'**
  String get tutorial_step2_title;

  /// No description provided for @tutorial_step2_body.
  ///
  /// In en, this message translates to:
  /// **'We’ll notify you when your request is approved or needs changes.'**
  String get tutorial_step2_body;

  /// No description provided for @tutorial_step3_title.
  ///
  /// In en, this message translates to:
  /// **'Download the APK'**
  String get tutorial_step3_title;

  /// No description provided for @tutorial_step3_body.
  ///
  /// In en, this message translates to:
  /// **'Once built, grab your APK directly from your dashboard.'**
  String get tutorial_step3_body;

  /// No description provided for @owner_projects_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or slug…'**
  String get owner_projects_searchHint;

  /// No description provided for @owner_projects_onlyReady.
  ///
  /// In en, this message translates to:
  /// **'Only APK ready'**
  String get owner_projects_onlyReady;

  /// No description provided for @owner_projects_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get owner_projects_emptyTitle;

  /// No description provided for @owner_projects_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'You don’t have any projects. Request your first app and we’ll build it for you.'**
  String get owner_projects_emptyBody;

  /// No description provided for @owner_projects_building.
  ///
  /// In en, this message translates to:
  /// **'Building…'**
  String get owner_projects_building;

  /// No description provided for @owner_projects_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get owner_projects_ready;

  /// No description provided for @owner_projects_openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get owner_projects_openInBrowser;

  /// No description provided for @owner_request_title.
  ///
  /// In en, this message translates to:
  /// **'Create App Request'**
  String get owner_request_title;

  /// No description provided for @owner_request_submit_hint.
  ///
  /// In en, this message translates to:
  /// **'Pick a project, name your app, add a logo (optional), choose a theme, then submit to build.'**
  String get owner_request_submit_hint;

  /// No description provided for @owner_request_project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get owner_request_project;

  /// No description provided for @owner_request_appName.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get owner_request_appName;

  /// No description provided for @owner_request_appName_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Owner App'**
  String get owner_request_appName_hint;

  /// No description provided for @owner_request_logo_url.
  ///
  /// In en, this message translates to:
  /// **'Logo URL (optional)'**
  String get owner_request_logo_url;

  /// No description provided for @owner_request_logo_url_hint.
  ///
  /// In en, this message translates to:
  /// **'Paste a public URL or use Upload'**
  String get owner_request_logo_url_hint;

  /// No description provided for @owner_request_upload_logo.
  ///
  /// In en, this message translates to:
  /// **'Upload logo file'**
  String get owner_request_upload_logo;

  /// No description provided for @owner_request_theme_pref.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get owner_request_theme_pref;

  /// No description provided for @owner_request_theme_default.
  ///
  /// In en, this message translates to:
  /// **'Use default theme'**
  String get owner_request_theme_default;

  /// No description provided for @owner_request_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get owner_request_submit;

  /// No description provided for @owner_request_submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get owner_request_submitting;

  /// No description provided for @owner_request_submit_and_build.
  ///
  /// In en, this message translates to:
  /// **'Submit & Build APK'**
  String get owner_request_submit_and_build;

  /// No description provided for @owner_request_building.
  ///
  /// In en, this message translates to:
  /// **'Building APK…'**
  String get owner_request_building;

  /// No description provided for @owner_request_build_done.
  ///
  /// In en, this message translates to:
  /// **'APK build completed.'**
  String get owner_request_build_done;

  /// No description provided for @owner_request_success.
  ///
  /// In en, this message translates to:
  /// **'Request submitted successfully.'**
  String get owner_request_success;

  /// No description provided for @owner_request_no_requests_yet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet.'**
  String get owner_request_no_requests_yet;

  /// No description provided for @owner_request_my_requests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get owner_request_my_requests;

  /// No description provided for @owner_request_error_choose_project.
  ///
  /// In en, this message translates to:
  /// **'Please choose a project.'**
  String get owner_request_error_choose_project;

  /// No description provided for @owner_request_error_app_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter an app name.'**
  String get owner_request_error_app_name;

  /// No description provided for @common_download.
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get common_download;

  /// No description provided for @common_download_apk.
  ///
  /// In en, this message translates to:
  /// **'Download APK'**
  String get common_download_apk;

  /// No description provided for @menuType.
  ///
  /// In en, this message translates to:
  /// **'Menu Type'**
  String get menuType;

  /// No description provided for @owner_profile_username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get owner_profile_username;

  /// No description provided for @owner_profile_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get owner_profile_name;

  /// No description provided for @owner_profile_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get owner_profile_email;

  /// No description provided for @owner_profile_business_id.
  ///
  /// In en, this message translates to:
  /// **'Business ID'**
  String get owner_profile_business_id;

  /// No description provided for @owner_profile_notify_items.
  ///
  /// In en, this message translates to:
  /// **'Notify item updates'**
  String get owner_profile_notify_items;

  /// No description provided for @owner_profile_notify_feedback.
  ///
  /// In en, this message translates to:
  /// **'Notify user feedback'**
  String get owner_profile_notify_feedback;

  /// No description provided for @owner_profile_not_set.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get owner_profile_not_set;

  /// No description provided for @owner_profile_tips.
  ///
  /// In en, this message translates to:
  /// **'Keep your profile details up to date to personalize your experience.'**
  String get owner_profile_tips;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logout_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to log out?'**
  String get logout_confirm;

  /// No description provided for @logged_out.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get logged_out;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @owner_nav_myapps.
  ///
  /// In en, this message translates to:
  /// **'My Apps'**
  String get owner_nav_myapps;

  /// No description provided for @common_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get common_search_hint;

  /// No description provided for @owner_home_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search apps, requests, guides'**
  String get owner_home_search_hint;

  /// No description provided for @owner_home_chooseProject.
  ///
  /// In en, this message translates to:
  /// **'Choose your project'**
  String get owner_home_chooseProject;

  /// No description provided for @owner_proj_open.
  ///
  /// In en, this message translates to:
  /// **'Open project'**
  String get owner_proj_open;

  /// No description provided for @owner_proj_activities_title.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get owner_proj_activities_title;

  /// No description provided for @owner_proj_activities_desc.
  ///
  /// In en, this message translates to:
  /// **'Ticketing, schedules, and event highlights crafted for experiences on the go.'**
  String get owner_proj_activities_desc;

  /// No description provided for @owner_proj_ecom_title.
  ///
  /// In en, this message translates to:
  /// **'E-commerce'**
  String get owner_proj_ecom_title;

  /// No description provided for @owner_proj_ecom_desc.
  ///
  /// In en, this message translates to:
  /// **'Product catalogs, carts, and checkout flows that mirror your storefront.'**
  String get owner_proj_ecom_desc;

  /// No description provided for @owner_proj_gym_title.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get owner_proj_gym_title;

  /// No description provided for @owner_proj_gym_desc.
  ///
  /// In en, this message translates to:
  /// **'Training plans, booking slots, and membership perks in one app.'**
  String get owner_proj_gym_desc;

  /// No description provided for @owner_proj_services_title.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get owner_proj_services_title;

  /// No description provided for @owner_proj_services_desc.
  ///
  /// In en, this message translates to:
  /// **'Quotes, appointments, and customer updates tailored to your brand.'**
  String get owner_proj_services_desc;

  /// No description provided for @status_delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get status_delivered;

  /// No description provided for @status_in_production.
  ///
  /// In en, this message translates to:
  /// **'In production'**
  String get status_in_production;

  /// No description provided for @status_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get status_approved;

  /// No description provided for @status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get status_pending;

  /// No description provided for @status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get status_rejected;

  /// No description provided for @owner_request_requested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get owner_request_requested;

  /// No description provided for @timeago_days.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeago_days(int count);

  /// No description provided for @timeago_hours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeago_hours(int count);

  /// No description provided for @timeago_minutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeago_minutes(int count);

  /// No description provided for @timeago_just_now.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeago_just_now;

  /// No description provided for @owner_proj_details_highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get owner_proj_details_highlights;

  /// No description provided for @owner_proj_details_screens.
  ///
  /// In en, this message translates to:
  /// **'Screens & flows'**
  String get owner_proj_details_screens;

  /// No description provided for @owner_proj_details_modules.
  ///
  /// In en, this message translates to:
  /// **'Modules included'**
  String get owner_proj_details_modules;

  /// No description provided for @owner_proj_details_why.
  ///
  /// In en, this message translates to:
  /// **'Why teams love this template'**
  String get owner_proj_details_why;

  /// No description provided for @owner_proj_details_primaryCta.
  ///
  /// In en, this message translates to:
  /// **'Request this app'**
  String get owner_proj_details_primaryCta;

  /// No description provided for @owner_proj_details_secondaryCta.
  ///
  /// In en, this message translates to:
  /// **'Preview demo'**
  String get owner_proj_details_secondaryCta;

  /// No description provided for @owner_proj_details_create_title.
  ///
  /// In en, this message translates to:
  /// **'Create my App'**
  String get owner_proj_details_create_title;

  /// No description provided for @owner_proj_details_create_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Launch your customized version in minutes.'**
  String get owner_proj_details_create_subtitle;

  /// No description provided for @stat_reviews_hint.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get stat_reviews_hint;

  /// No description provided for @stat_active_hint.
  ///
  /// In en, this message translates to:
  /// **'active deployments'**
  String get stat_active_hint;

  /// No description provided for @stat_days_hint.
  ///
  /// In en, this message translates to:
  /// **'days avg. turnaround'**
  String get stat_days_hint;

  /// No description provided for @owner_proj_details_headline_activities.
  ///
  /// In en, this message translates to:
  /// **'Plan, book, and manage every activity in one place.'**
  String get owner_proj_details_headline_activities;

  /// No description provided for @owner_proj_details_subhead_activities.
  ///
  /// In en, this message translates to:
  /// **'Perfect for studios, clubs, and programs with polished booking & schedules.'**
  String get owner_proj_details_subhead_activities;

  /// No description provided for @owner_proj_details_act_h1.
  ///
  /// In en, this message translates to:
  /// **'Class schedules with waitlists'**
  String get owner_proj_details_act_h1;

  /// No description provided for @owner_proj_details_act_h2.
  ///
  /// In en, this message translates to:
  /// **'Wallet & credits support'**
  String get owner_proj_details_act_h2;

  /// No description provided for @owner_proj_details_act_h3.
  ///
  /// In en, this message translates to:
  /// **'Push reminders for attendees'**
  String get owner_proj_details_act_h3;

  /// No description provided for @owner_proj_details_act_h4.
  ///
  /// In en, this message translates to:
  /// **'Embedded community feed'**
  String get owner_proj_details_act_h4;

  /// No description provided for @owner_proj_details_act_s1_title.
  ///
  /// In en, this message translates to:
  /// **'Schedule grid'**
  String get owner_proj_details_act_s1_title;

  /// No description provided for @owner_proj_details_act_s1_sub.
  ///
  /// In en, this message translates to:
  /// **'Filter by instructor & location with one tap.'**
  String get owner_proj_details_act_s1_sub;

  /// No description provided for @owner_proj_details_act_s2_title.
  ///
  /// In en, this message translates to:
  /// **'Booking flow'**
  String get owner_proj_details_act_s2_title;

  /// No description provided for @owner_proj_details_act_s2_sub.
  ///
  /// In en, this message translates to:
  /// **'Frictionless checkout with saved cards.'**
  String get owner_proj_details_act_s2_sub;

  /// No description provided for @owner_proj_details_act_m1.
  ///
  /// In en, this message translates to:
  /// **'Dynamic schedules & multi-location calendars'**
  String get owner_proj_details_act_m1;

  /// No description provided for @owner_proj_details_act_m2.
  ///
  /// In en, this message translates to:
  /// **'Instructor bios and ratings'**
  String get owner_proj_details_act_m2;

  /// No description provided for @owner_proj_details_act_m3.
  ///
  /// In en, this message translates to:
  /// **'Membership tiers with perks'**
  String get owner_proj_details_act_m3;

  /// No description provided for @owner_proj_details_act_i1.
  ///
  /// In en, this message translates to:
  /// **'78% of members book via mobile within the first week.'**
  String get owner_proj_details_act_i1;

  /// No description provided for @owner_proj_details_act_i2.
  ///
  /// In en, this message translates to:
  /// **'Retention jumps 24% after enabling reminder pushes.'**
  String get owner_proj_details_act_i2;

  /// No description provided for @owner_proj_details_headline_ecommerce.
  ///
  /// In en, this message translates to:
  /// **'Launch a high-converting storefront your shoppers trust.'**
  String get owner_proj_details_headline_ecommerce;

  /// No description provided for @owner_proj_details_subhead_ecommerce.
  ///
  /// In en, this message translates to:
  /// **'For DTC brands: catalogs, bundles, and one-click reorders.'**
  String get owner_proj_details_subhead_ecommerce;

  /// No description provided for @owner_proj_details_ecom_h1.
  ///
  /// In en, this message translates to:
  /// **'Visual catalog with rich media'**
  String get owner_proj_details_ecom_h1;

  /// No description provided for @owner_proj_details_ecom_h2.
  ///
  /// In en, this message translates to:
  /// **'Smart upsell recommendations'**
  String get owner_proj_details_ecom_h2;

  /// No description provided for @owner_proj_details_ecom_h3.
  ///
  /// In en, this message translates to:
  /// **'In-app order tracking'**
  String get owner_proj_details_ecom_h3;

  /// No description provided for @owner_proj_details_ecom_h4.
  ///
  /// In en, this message translates to:
  /// **'Discount & loyalty engine'**
  String get owner_proj_details_ecom_h4;

  /// No description provided for @owner_proj_details_ecom_s1_title.
  ///
  /// In en, this message translates to:
  /// **'Product showcase'**
  String get owner_proj_details_ecom_s1_title;

  /// No description provided for @owner_proj_details_ecom_s1_sub.
  ///
  /// In en, this message translates to:
  /// **'Full-bleed imagery with swatches.'**
  String get owner_proj_details_ecom_s1_sub;

  /// No description provided for @owner_proj_details_ecom_s2_title.
  ///
  /// In en, this message translates to:
  /// **'Cart & checkout'**
  String get owner_proj_details_ecom_s2_title;

  /// No description provided for @owner_proj_details_ecom_s2_sub.
  ///
  /// In en, this message translates to:
  /// **'Accelerated checkout with saved addresses.'**
  String get owner_proj_details_ecom_s2_sub;

  /// No description provided for @owner_proj_details_ecom_m1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited product variants & bundles'**
  String get owner_proj_details_ecom_m1;

  /// No description provided for @owner_proj_details_ecom_m2.
  ///
  /// In en, this message translates to:
  /// **'Inventory sync with Shopify/Woo'**
  String get owner_proj_details_ecom_m2;

  /// No description provided for @owner_proj_details_ecom_m3.
  ///
  /// In en, this message translates to:
  /// **'Gift cards and referral rewards'**
  String get owner_proj_details_ecom_m3;

  /// No description provided for @owner_proj_details_ecom_i1.
  ///
  /// In en, this message translates to:
  /// **'Average order value lifts 32% with bundled offers.'**
  String get owner_proj_details_ecom_i1;

  /// No description provided for @owner_proj_details_ecom_i2.
  ///
  /// In en, this message translates to:
  /// **'Customers reorder 2.1× faster via the mobile channel.'**
  String get owner_proj_details_ecom_i2;

  /// No description provided for @owner_proj_details_headline_gym.
  ///
  /// In en, this message translates to:
  /// **'Give members a personal coach in their pocket.'**
  String get owner_proj_details_headline_gym;

  /// No description provided for @owner_proj_details_subhead_gym.
  ///
  /// In en, this message translates to:
  /// **'Hybrid training, class packs, and equipment rentals.'**
  String get owner_proj_details_subhead_gym;

  /// No description provided for @owner_proj_details_gym_h1.
  ///
  /// In en, this message translates to:
  /// **'Goal-based onboarding'**
  String get owner_proj_details_gym_h1;

  /// No description provided for @owner_proj_details_gym_h2.
  ///
  /// In en, this message translates to:
  /// **'Trainer messaging & programs'**
  String get owner_proj_details_gym_h2;

  /// No description provided for @owner_proj_details_gym_h3.
  ///
  /// In en, this message translates to:
  /// **'Workout video library'**
  String get owner_proj_details_gym_h3;

  /// No description provided for @owner_proj_details_gym_h4.
  ///
  /// In en, this message translates to:
  /// **'Progress tracking dashboards'**
  String get owner_proj_details_gym_h4;

  /// No description provided for @owner_proj_details_gym_s1_title.
  ///
  /// In en, this message translates to:
  /// **'Training plans'**
  String get owner_proj_details_gym_s1_title;

  /// No description provided for @owner_proj_details_gym_s1_sub.
  ///
  /// In en, this message translates to:
  /// **'Periodised plans with rest logic.'**
  String get owner_proj_details_gym_s1_sub;

  /// No description provided for @owner_proj_details_gym_s2_title.
  ///
  /// In en, this message translates to:
  /// **'Live classes'**
  String get owner_proj_details_gym_s2_title;

  /// No description provided for @owner_proj_details_gym_s2_sub.
  ///
  /// In en, this message translates to:
  /// **'Book in-person or virtual sessions.'**
  String get owner_proj_details_gym_s2_sub;

  /// No description provided for @owner_proj_details_gym_m1.
  ///
  /// In en, this message translates to:
  /// **'Trainer marketplace with availability'**
  String get owner_proj_details_gym_m1;

  /// No description provided for @owner_proj_details_gym_m2.
  ///
  /// In en, this message translates to:
  /// **'Workout logging & wearable sync'**
  String get owner_proj_details_gym_m2;

  /// No description provided for @owner_proj_details_gym_m3.
  ///
  /// In en, this message translates to:
  /// **'Nutrition plans with macro targets'**
  String get owner_proj_details_gym_m3;

  /// No description provided for @owner_proj_details_gym_i1.
  ///
  /// In en, this message translates to:
  /// **'Members completing onboarding convert 3× faster.'**
  String get owner_proj_details_gym_i1;

  /// No description provided for @owner_proj_details_gym_i2.
  ///
  /// In en, this message translates to:
  /// **'Churn drops 19% when messaging is enabled.'**
  String get owner_proj_details_gym_i2;

  /// No description provided for @owner_proj_details_headline_services.
  ///
  /// In en, this message translates to:
  /// **'Deliver a concierge-grade service experience.'**
  String get owner_proj_details_headline_services;

  /// No description provided for @owner_proj_details_subhead_services.
  ///
  /// In en, this message translates to:
  /// **'For agencies, consultancies, and service pros.'**
  String get owner_proj_details_subhead_services;

  /// No description provided for @owner_proj_details_services_h1.
  ///
  /// In en, this message translates to:
  /// **'Smart booking windows'**
  String get owner_proj_details_services_h1;

  /// No description provided for @owner_proj_details_services_h2.
  ///
  /// In en, this message translates to:
  /// **'Client workspaces'**
  String get owner_proj_details_services_h2;

  /// No description provided for @owner_proj_details_services_h3.
  ///
  /// In en, this message translates to:
  /// **'Task & milestone tracker'**
  String get owner_proj_details_services_h3;

  /// No description provided for @owner_proj_details_services_h4.
  ///
  /// In en, this message translates to:
  /// **'Integrated invoicing'**
  String get owner_proj_details_services_h4;

  /// No description provided for @owner_proj_details_services_s1_title.
  ///
  /// In en, this message translates to:
  /// **'Client portal'**
  String get owner_proj_details_services_s1_title;

  /// No description provided for @owner_proj_details_services_s1_sub.
  ///
  /// In en, this message translates to:
  /// **'Shared files, notes, and approvals.'**
  String get owner_proj_details_services_s1_sub;

  /// No description provided for @owner_proj_details_services_s2_title.
  ///
  /// In en, this message translates to:
  /// **'Appointment flow'**
  String get owner_proj_details_services_s2_title;

  /// No description provided for @owner_proj_details_services_s2_sub.
  ///
  /// In en, this message translates to:
  /// **'Buffers and intake forms.'**
  String get owner_proj_details_services_s2_sub;

  /// No description provided for @owner_proj_details_services_m1.
  ///
  /// In en, this message translates to:
  /// **'Client CRM with shared timelines'**
  String get owner_proj_details_services_m1;

  /// No description provided for @owner_proj_details_services_m2.
  ///
  /// In en, this message translates to:
  /// **'Digital contracts & e-signatures'**
  String get owner_proj_details_services_m2;

  /// No description provided for @owner_proj_details_services_m3.
  ///
  /// In en, this message translates to:
  /// **'Automated invoice & receipt emails'**
  String get owner_proj_details_services_m3;

  /// No description provided for @owner_proj_details_services_i1.
  ///
  /// In en, this message translates to:
  /// **'Projects close 27% faster with shared workspaces.'**
  String get owner_proj_details_services_i1;

  /// No description provided for @owner_proj_details_services_i2.
  ///
  /// In en, this message translates to:
  /// **'Automated billing reduces late payments by 43%.'**
  String get owner_proj_details_services_i2;

  /// No description provided for @owner_proj_details_stat_reviews_hint.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get owner_proj_details_stat_reviews_hint;

  /// No description provided for @owner_proj_details_stat_active_hint.
  ///
  /// In en, this message translates to:
  /// **'active deployments'**
  String get owner_proj_details_stat_active_hint;

  /// No description provided for @owner_proj_details_stat_days_hint.
  ///
  /// In en, this message translates to:
  /// **'days avg. turnaround'**
  String get owner_proj_details_stat_days_hint;

  /// No description provided for @owner_projects_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your projects and app builds seamlessly'**
  String get owner_projects_subtitle;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get change_password;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @contact_us.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contact_us;

  /// No description provided for @owner_profile_edit.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get owner_profile_edit;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get edit_profile;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @owner_proj_comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get owner_proj_comingSoon;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @common_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get common_remove;

  /// No description provided for @owner_request_hero_title.
  ///
  /// In en, this message translates to:
  /// **'Build a new app'**
  String get owner_request_hero_title;

  /// No description provided for @owner_request_hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick theme + runtime visually. We generate JSON behind the scenes.'**
  String get owner_request_hero_subtitle;

  /// No description provided for @owner_request_basics_title.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get owner_request_basics_title;

  /// No description provided for @owner_request_basics_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Required info to generate your app.'**
  String get owner_request_basics_subtitle;

  /// No description provided for @owner_request_project_id.
  ///
  /// In en, this message translates to:
  /// **'Project ID'**
  String get owner_request_project_id;

  /// No description provided for @owner_request_project_id_hint.
  ///
  /// In en, this message translates to:
  /// **'Selected from project'**
  String get owner_request_project_id_hint;

  /// No description provided for @owner_request_app_name.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get owner_request_app_name;

  /// No description provided for @owner_request_app_name_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: MyHobbySphereApp'**
  String get owner_request_app_name_hint;

  /// No description provided for @owner_request_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get owner_request_notes;

  /// No description provided for @owner_request_notes_hint.
  ///
  /// In en, this message translates to:
  /// **'Short description / special request / anything important…'**
  String get owner_request_notes_hint;

  /// No description provided for @owner_request_settings_title.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get owner_request_settings_title;

  /// No description provided for @owner_request_settings_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Currency + optional API override.'**
  String get owner_request_settings_subtitle;

  /// No description provided for @owner_request_api_override.
  ///
  /// In en, this message translates to:
  /// **'API base URL override (optional)'**
  String get owner_request_api_override;

  /// No description provided for @owner_request_api_override_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: http://192.168.1.7:8080'**
  String get owner_request_api_override_hint;

  /// No description provided for @owner_request_palette_title.
  ///
  /// In en, this message translates to:
  /// **'Palette'**
  String get owner_request_palette_title;

  /// No description provided for @owner_request_palette_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a preset or customize colors.'**
  String get owner_request_palette_subtitle;

  /// No description provided for @owner_request_runtime_title.
  ///
  /// In en, this message translates to:
  /// **'Runtime Config'**
  String get owner_request_runtime_title;

  /// No description provided for @owner_request_runtime_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation + home layout + feature flags (no JSON typing).'**
  String get owner_request_runtime_subtitle;

  /// No description provided for @owner_request_branding_title.
  ///
  /// In en, this message translates to:
  /// **'Branding'**
  String get owner_request_branding_title;

  /// No description provided for @owner_request_branding_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Logo is optional but makes it look legit.'**
  String get owner_request_branding_subtitle;

  /// No description provided for @owner_request_err_load_currencies.
  ///
  /// In en, this message translates to:
  /// **'Failed to load currencies'**
  String get owner_request_err_load_currencies;

  /// No description provided for @owner_request_err_valid_number.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get owner_request_err_valid_number;

  /// No description provided for @owner_request_err_select_currency.
  ///
  /// In en, this message translates to:
  /// **'Select a currency first'**
  String get owner_request_err_select_currency;

  /// No description provided for @owner_request_err_fix_fields.
  ///
  /// In en, this message translates to:
  /// **'Fix the highlighted fields'**
  String get owner_request_err_fix_fields;

  /// No description provided for @owner_request_err_app_name_required.
  ///
  /// In en, this message translates to:
  /// **'App name is required'**
  String get owner_request_err_app_name_required;

  /// No description provided for @owner_request_logo_selected.
  ///
  /// In en, this message translates to:
  /// **'Logo selected'**
  String get owner_request_logo_selected;

  /// No description provided for @owner_request_logo_removed.
  ///
  /// In en, this message translates to:
  /// **'Logo removed'**
  String get owner_request_logo_removed;

  /// No description provided for @owner_request_no_logo.
  ///
  /// In en, this message translates to:
  /// **'No logo selected'**
  String get owner_request_no_logo;

  /// No description provided for @owner_request_pick_logo.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get owner_request_pick_logo;

  /// No description provided for @owner_request_select_currency.
  ///
  /// In en, this message translates to:
  /// **'Select currency'**
  String get owner_request_select_currency;

  /// No description provided for @owner_request_tap_to_choose.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose'**
  String get owner_request_tap_to_choose;

  /// No description provided for @owner_request_pick_currency.
  ///
  /// In en, this message translates to:
  /// **'Pick currency'**
  String get owner_request_pick_currency;

  /// No description provided for @owner_request_currency_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search by label / code / id'**
  String get owner_request_currency_search_hint;

  /// No description provided for @owner_request_currency_set.
  ///
  /// In en, this message translates to:
  /// **'Currency set to {code}'**
  String owner_request_currency_set(String code);

  /// No description provided for @owner_request_submit_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready to submit?'**
  String get owner_request_submit_ready;

  /// No description provided for @owner_request_submit_success.
  ///
  /// In en, this message translates to:
  /// **'Request submitted ✅ CI started. APK soon 🚀'**
  String get owner_request_submit_success;

  /// No description provided for @owner_request_submit_failed.
  ///
  /// In en, this message translates to:
  /// **'Submit failed: {msg}'**
  String owner_request_submit_failed(String msg);

  /// No description provided for @owner_request_selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get owner_request_selected;

  /// No description provided for @owner_request_tap_to_apply.
  ///
  /// In en, this message translates to:
  /// **'Tap to apply'**
  String get owner_request_tap_to_apply;

  /// No description provided for @owner_request_primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get owner_request_primary;

  /// No description provided for @owner_request_secondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get owner_request_secondary;

  /// No description provided for @owner_request_background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get owner_request_background;

  /// No description provided for @owner_request_text_on_background.
  ///
  /// In en, this message translates to:
  /// **'Text (onBackground)'**
  String get owner_request_text_on_background;

  /// No description provided for @owner_request_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get owner_request_error;

  /// No description provided for @owner_request_pick_primary.
  ///
  /// In en, this message translates to:
  /// **'Pick Primary'**
  String get owner_request_pick_primary;

  /// No description provided for @owner_request_pick_secondary.
  ///
  /// In en, this message translates to:
  /// **'Pick Secondary'**
  String get owner_request_pick_secondary;

  /// No description provided for @owner_request_pick_background.
  ///
  /// In en, this message translates to:
  /// **'Pick Background'**
  String get owner_request_pick_background;

  /// No description provided for @owner_request_pick_text_color.
  ///
  /// In en, this message translates to:
  /// **'Pick Text Color'**
  String get owner_request_pick_text_color;

  /// No description provided for @owner_request_pick_error.
  ///
  /// In en, this message translates to:
  /// **'Pick Error'**
  String get owner_request_pick_error;

  /// No description provided for @owner_request_quick_colors.
  ///
  /// In en, this message translates to:
  /// **'Quick colors'**
  String get owner_request_quick_colors;

  /// No description provided for @owner_request_hex_optional.
  ///
  /// In en, this message translates to:
  /// **'Hex (optional)'**
  String get owner_request_hex_optional;

  /// No description provided for @owner_request_hex_hint.
  ///
  /// In en, this message translates to:
  /// **'#RRGGBB'**
  String get owner_request_hex_hint;

  /// No description provided for @owner_request_err_hex_format.
  ///
  /// In en, this message translates to:
  /// **'Use #RRGGBB'**
  String get owner_request_err_hex_format;

  /// No description provided for @owner_request_your_app.
  ///
  /// In en, this message translates to:
  /// **'Your App'**
  String get owner_request_your_app;

  /// No description provided for @owner_request_preview_hello_owner.
  ///
  /// In en, this message translates to:
  /// **'Hello owner 👋'**
  String get owner_request_preview_hello_owner;

  /// No description provided for @owner_request_preview_desc.
  ///
  /// In en, this message translates to:
  /// **'This is how your theme looks.'**
  String get owner_request_preview_desc;

  /// No description provided for @super_create_project_title.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get super_create_project_title;

  /// No description provided for @super_create_project_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new project template for owners to use.'**
  String get super_create_project_subtitle;

  /// No description provided for @super_project_name.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get super_project_name;

  /// No description provided for @super_project_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Example: HobbySphere'**
  String get super_project_name_hint;

  /// No description provided for @super_project_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get super_project_description;

  /// No description provided for @super_project_description_hint.
  ///
  /// In en, this message translates to:
  /// **'Short description (optional)'**
  String get super_project_description_hint;

  /// No description provided for @super_project_type.
  ///
  /// In en, this message translates to:
  /// **'Project type'**
  String get super_project_type;

  /// No description provided for @project_type_ecommerce.
  ///
  /// In en, this message translates to:
  /// **'E-commerce'**
  String get project_type_ecommerce;

  /// No description provided for @project_type_services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get project_type_services;

  /// No description provided for @project_type_activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get project_type_activities;

  /// No description provided for @super_project_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get super_project_active;

  /// No description provided for @super_project_active_hint.
  ///
  /// In en, this message translates to:
  /// **'If disabled, owners can’t use it until activated.'**
  String get super_project_active_hint;

  /// No description provided for @super_create_project_btn.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get super_create_project_btn;

  /// No description provided for @super_create_another.
  ///
  /// In en, this message translates to:
  /// **'Create another'**
  String get super_create_another;

  /// No description provided for @super_project_name_required.
  ///
  /// In en, this message translates to:
  /// **'Project name is required'**
  String get super_project_name_required;

  /// No description provided for @super_project_name_exists.
  ///
  /// In en, this message translates to:
  /// **'This project name already exists'**
  String get super_project_name_exists;

  /// No description provided for @super_create_project_created_id.
  ///
  /// In en, this message translates to:
  /// **'Created successfully (ID: {id})'**
  String super_create_project_created_id(String id);

  /// No description provided for @super_create_project_success.
  ///
  /// In en, this message translates to:
  /// **'Project \"{name}\" created successfully!'**
  String super_create_project_success(String name);

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_forbidden.
  ///
  /// In en, this message translates to:
  /// **'Forbidden'**
  String get common_forbidden;

  /// No description provided for @common_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized'**
  String get common_unauthorized;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @search_owners_hint.
  ///
  /// In en, this message translates to:
  /// **'Search owners…'**
  String get search_owners_hint;

  /// No description provided for @search_apps_hint.
  ///
  /// In en, this message translates to:
  /// **'Search apps…'**
  String get search_apps_hint;

  /// No description provided for @empty_owners.
  ///
  /// In en, this message translates to:
  /// **'No owners found'**
  String get empty_owners;

  /// No description provided for @empty_owner_apps.
  ///
  /// In en, this message translates to:
  /// **'No apps found for this owner'**
  String get empty_owner_apps;

  /// No description provided for @unnamed_app.
  ///
  /// In en, this message translates to:
  /// **'(Unnamed App)'**
  String get unnamed_app;

  /// No description provided for @toast_app_selected.
  ///
  /// In en, this message translates to:
  /// **'App: {slug}'**
  String toast_app_selected(Object slug);

  /// No description provided for @app_slug_status.
  ///
  /// In en, this message translates to:
  /// **'slug: {slug} • {status}'**
  String app_slug_status(Object slug, Object status);

  /// No description provided for @apps_count.
  ///
  /// In en, this message translates to:
  /// **'{count} apps'**
  String apps_count(Object count);

  /// No description provided for @ordersLabel.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersLabel;

  /// No description provided for @orderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderLabel;

  /// No description provided for @noOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get noOrdersTitle;

  /// No description provided for @noOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No orders found for this app with the current filters.'**
  String get noOrdersSubtitle;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @allTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTimeLabel;

  /// No description provided for @dashboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardLabel;

  /// No description provided for @last7DaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7DaysLabel;

  /// No description provided for @last30DaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30DaysLabel;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @grossSalesLabel.
  ///
  /// In en, this message translates to:
  /// **'Gross sales'**
  String get grossSalesLabel;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @outstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstandingLabel;

  /// No description provided for @avgOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Average order value'**
  String get avgOrderLabel;

  /// No description provided for @fullyPaidRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Fully paid'**
  String get fullyPaidRateLabel;

  /// No description provided for @statusBreakdownLabel.
  ///
  /// In en, this message translates to:
  /// **'Status breakdown'**
  String get statusBreakdownLabel;

  /// No description provided for @paidRevenueLast7DaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid revenue (last 7 days)'**
  String get paidRevenueLast7DaysLabel;

  /// No description provided for @filterAllLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAllLabel;

  /// No description provided for @filterPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPendingLabel;

  /// No description provided for @filterCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompletedLabel;

  /// No description provided for @filterCanceledLabel.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get filterCanceledLabel;

  /// No description provided for @filterRejectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get filterRejectedLabel;

  /// No description provided for @filterRefundedLabel.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get filterRefundedLabel;

  /// No description provided for @itemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// No description provided for @fullyPaidShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Fully paid'**
  String get fullyPaidShortLabel;

  /// No description provided for @owner_projects_test.
  ///
  /// In en, this message translates to:
  /// **'TEST'**
  String get owner_projects_test;

  /// No description provided for @owner_publish_title_play.
  ///
  /// In en, this message translates to:
  /// **'Publish to Google Play Store'**
  String get owner_publish_title_play;

  /// No description provided for @owner_publish_title_appstore.
  ///
  /// In en, this message translates to:
  /// **'Publish to App Store'**
  String get owner_publish_title_appstore;

  /// No description provided for @owner_publish_platform_android.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get owner_publish_platform_android;

  /// No description provided for @owner_publish_platform_ios.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get owner_publish_platform_ios;

  /// No description provided for @owner_publish_request_play.
  ///
  /// In en, this message translates to:
  /// **'Request Publish to Play Store'**
  String get owner_publish_request_play;

  /// No description provided for @owner_publish_request_appstore.
  ///
  /// In en, this message translates to:
  /// **'Request Publish to App Store'**
  String get owner_publish_request_appstore;

  /// No description provided for @owner_publish_step1_title.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get owner_publish_step1_title;

  /// No description provided for @owner_publish_step1_sub.
  ///
  /// In en, this message translates to:
  /// **'Provide the basic details about your application'**
  String get owner_publish_step1_sub;

  /// No description provided for @owner_publish_step2_title.
  ///
  /// In en, this message translates to:
  /// **'Category & Details'**
  String get owner_publish_step2_title;

  /// No description provided for @owner_publish_step2_sub.
  ///
  /// In en, this message translates to:
  /// **'Categorize your app and provide additional details'**
  String get owner_publish_step2_sub;

  /// No description provided for @owner_publish_step3_title.
  ///
  /// In en, this message translates to:
  /// **'Legal & Contact'**
  String get owner_publish_step3_title;

  /// No description provided for @owner_publish_step3_sub.
  ///
  /// In en, this message translates to:
  /// **'These fields are managed by Build4All publisher profile'**
  String get owner_publish_step3_sub;

  /// No description provided for @owner_publish_step4_title.
  ///
  /// In en, this message translates to:
  /// **'Assets & Screenshots'**
  String get owner_publish_step4_title;

  /// No description provided for @owner_publish_step4_sub.
  ///
  /// In en, this message translates to:
  /// **'Provide your app icon and screenshots URLs'**
  String get owner_publish_step4_sub;

  /// No description provided for @owner_publish_app_name.
  ///
  /// In en, this message translates to:
  /// **'Application Name'**
  String get owner_publish_app_name;

  /// No description provided for @owner_publish_app_name_hint.
  ///
  /// In en, this message translates to:
  /// **'ShopSphere'**
  String get owner_publish_app_name_hint;

  /// No description provided for @owner_publish_package_name.
  ///
  /// In en, this message translates to:
  /// **'Package Name (Read-only)'**
  String get owner_publish_package_name;

  /// No description provided for @owner_publish_bundle_id.
  ///
  /// In en, this message translates to:
  /// **'Bundle ID (Read-only)'**
  String get owner_publish_bundle_id;

  /// No description provided for @owner_publish_short_desc.
  ///
  /// In en, this message translates to:
  /// **'Short Description'**
  String get owner_publish_short_desc;

  /// No description provided for @owner_publish_short_desc_hint.
  ///
  /// In en, this message translates to:
  /// **'Brief app description (max 80 characters)'**
  String get owner_publish_short_desc_hint;

  /// No description provided for @owner_publish_full_desc.
  ///
  /// In en, this message translates to:
  /// **'Full Description'**
  String get owner_publish_full_desc;

  /// No description provided for @owner_publish_full_desc_hint.
  ///
  /// In en, this message translates to:
  /// **'Write a full store listing description…'**
  String get owner_publish_full_desc_hint;

  /// No description provided for @owner_publish_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get owner_publish_category;

  /// No description provided for @owner_publish_category_hint.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get owner_publish_category_hint;

  /// No description provided for @owner_publish_country.
  ///
  /// In en, this message translates to:
  /// **'Country Availability'**
  String get owner_publish_country;

  /// No description provided for @owner_publish_pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get owner_publish_pricing;

  /// No description provided for @owner_publish_free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get owner_publish_free;

  /// No description provided for @owner_publish_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get owner_publish_paid;

  /// No description provided for @owner_publish_content_confirm.
  ///
  /// In en, this message translates to:
  /// **'I confirm that this app complies with store policies and age-appropriate guidelines.'**
  String get owner_publish_content_confirm;

  /// No description provided for @owner_publish_privacy_url.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy URL'**
  String get owner_publish_privacy_url;

  /// No description provided for @owner_publish_dev_name.
  ///
  /// In en, this message translates to:
  /// **'Developer Name'**
  String get owner_publish_dev_name;

  /// No description provided for @owner_publish_dev_email.
  ///
  /// In en, this message translates to:
  /// **'Developer Email'**
  String get owner_publish_dev_email;

  /// No description provided for @owner_publish_managed_by_build4all.
  ///
  /// In en, this message translates to:
  /// **'Managed by Build4All'**
  String get owner_publish_managed_by_build4all;

  /// No description provided for @owner_publish_icon_url.
  ///
  /// In en, this message translates to:
  /// **'App Icon URL'**
  String get owner_publish_icon_url;

  /// No description provided for @owner_publish_icon_url_hint.
  ///
  /// In en, this message translates to:
  /// **'https://.../icon.png'**
  String get owner_publish_icon_url_hint;

  /// No description provided for @owner_publish_screenshots_urls.
  ///
  /// In en, this message translates to:
  /// **'Screenshots URLs'**
  String get owner_publish_screenshots_urls;

  /// No description provided for @owner_publish_screenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get owner_publish_screenshot;

  /// No description provided for @owner_publish_shots_rule.
  ///
  /// In en, this message translates to:
  /// **'Required: min 2, max 8 screenshots'**
  String get owner_publish_shots_rule;

  /// No description provided for @owner_publish_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get owner_publish_submit;

  /// No description provided for @owner_publish_submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted for review'**
  String get owner_publish_submitted;

  /// No description provided for @owner_publish_err_appname.
  ///
  /// In en, this message translates to:
  /// **'Application name is required'**
  String get owner_publish_err_appname;

  /// No description provided for @owner_publish_err_short.
  ///
  /// In en, this message translates to:
  /// **'Short description is required'**
  String get owner_publish_err_short;

  /// No description provided for @owner_publish_err_short80.
  ///
  /// In en, this message translates to:
  /// **'Short description max 80 characters'**
  String get owner_publish_err_short80;

  /// No description provided for @owner_publish_err_full.
  ///
  /// In en, this message translates to:
  /// **'Full description is required'**
  String get owner_publish_err_full;

  /// No description provided for @owner_publish_err_category.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get owner_publish_err_category;

  /// No description provided for @owner_publish_err_content_confirm.
  ///
  /// In en, this message translates to:
  /// **'You must confirm content rating compliance'**
  String get owner_publish_err_content_confirm;

  /// No description provided for @owner_publish_err_icon.
  ///
  /// In en, this message translates to:
  /// **'App icon URL is required'**
  String get owner_publish_err_icon;

  /// No description provided for @owner_publish_err_shots2.
  ///
  /// In en, this message translates to:
  /// **'At least 2 screenshots are required'**
  String get owner_publish_err_shots2;

  /// No description provided for @owner_publish_err_shots8.
  ///
  /// In en, this message translates to:
  /// **'Max 8 screenshots allowed'**
  String get owner_publish_err_shots8;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @errFixForm.
  ///
  /// In en, this message translates to:
  /// **'Please fix the errors in the form'**
  String get errFixForm;

  /// No description provided for @msgWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get msgWelcomeBack;

  /// No description provided for @msgVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get msgVerified;

  /// No description provided for @nav_publish_requests.
  ///
  /// In en, this message translates to:
  /// **'Publish Requests'**
  String get nav_publish_requests;

  /// No description provided for @publish_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search by app name, AUP id…'**
  String get publish_search_hint;

  /// No description provided for @publish_no_requests.
  ///
  /// In en, this message translates to:
  /// **'No requests found.'**
  String get publish_no_requests;

  /// No description provided for @common_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get common_refresh;

  /// No description provided for @publish_status_submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get publish_status_submitted;

  /// No description provided for @publish_status_in_review.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get publish_status_in_review;

  /// No description provided for @publish_status_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get publish_status_approved;

  /// No description provided for @publish_status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get publish_status_rejected;

  /// No description provided for @publish_status_published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get publish_status_published;

  /// No description provided for @publish_status_draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get publish_status_draft;

  /// No description provided for @publish_details_title.
  ///
  /// In en, this message translates to:
  /// **'Publish Request'**
  String get publish_details_title;

  /// No description provided for @publish_section_basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get publish_section_basic;

  /// No description provided for @publish_section_descriptions.
  ///
  /// In en, this message translates to:
  /// **'Descriptions'**
  String get publish_section_descriptions;

  /// No description provided for @publish_section_assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get publish_section_assets;

  /// No description provided for @publish_section_admin_notes.
  ///
  /// In en, this message translates to:
  /// **'Admin Notes'**
  String get publish_section_admin_notes;

  /// No description provided for @publish_label_platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get publish_label_platform;

  /// No description provided for @publish_label_store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get publish_label_store;

  /// No description provided for @publish_label_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get publish_label_status;

  /// No description provided for @publish_label_aup.
  ///
  /// In en, this message translates to:
  /// **'AUP'**
  String get publish_label_aup;

  /// No description provided for @publish_label_package.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get publish_label_package;

  /// No description provided for @publish_label_bundle.
  ///
  /// In en, this message translates to:
  /// **'Bundle ID'**
  String get publish_label_bundle;

  /// No description provided for @publish_label_pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get publish_label_pricing;

  /// No description provided for @publish_label_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get publish_label_category;

  /// No description provided for @publish_label_content_rating_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Content rating confirmed'**
  String get publish_label_content_rating_confirmed;

  /// No description provided for @publish_label_short.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get publish_label_short;

  /// No description provided for @publish_label_full.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get publish_label_full;

  /// No description provided for @publish_label_icon.
  ///
  /// In en, this message translates to:
  /// **'App Icon'**
  String get publish_label_icon;

  /// No description provided for @publish_label_screenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get publish_label_screenshots;

  /// No description provided for @publish_label_no_screenshots.
  ///
  /// In en, this message translates to:
  /// **'No screenshots'**
  String get publish_label_no_screenshots;

  /// No description provided for @publish_action_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get publish_action_reject;

  /// No description provided for @publish_action_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get publish_action_approve;

  /// No description provided for @publish_sheet_reject_title.
  ///
  /// In en, this message translates to:
  /// **'Reject request'**
  String get publish_sheet_reject_title;

  /// No description provided for @publish_sheet_approve_title.
  ///
  /// In en, this message translates to:
  /// **'Approve request'**
  String get publish_sheet_approve_title;

  /// No description provided for @publish_sheet_notes_hint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes…'**
  String get publish_sheet_notes_hint;

  /// No description provided for @toast_publish_approved.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get toast_publish_approved;

  /// No description provided for @toast_publish_rejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get toast_publish_rejected;

  /// No description provided for @super_nav_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get super_nav_dashboard;

  /// No description provided for @super_nav_publish_requests.
  ///
  /// In en, this message translates to:
  /// **'Publish Requests'**
  String get super_nav_publish_requests;

  /// No description provided for @super_nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get super_nav_profile;

  /// No description provided for @err_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized'**
  String get err_unauthorized;

  /// No description provided for @super_nav_create_project.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get super_nav_create_project;

  /// No description provided for @publish_manage_publisher_profiles.
  ///
  /// In en, this message translates to:
  /// **'Manage Publisher Profiles'**
  String get publish_manage_publisher_profiles;

  /// No description provided for @common_seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get common_seed;

  /// No description provided for @common_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get common_saving;

  /// No description provided for @common_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved ✅'**
  String get common_saved;

  /// No description provided for @common_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get common_save_failed;

  /// No description provided for @common_open.
  ///
  /// In en, this message translates to:
  /// **'Ouvrir'**
  String get common_open;

  /// No description provided for @common_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get common_unknown;

  /// No description provided for @common_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get common_status;

  /// No description provided for @common_fill_all_fields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get common_fill_all_fields;

  /// No description provided for @publish_store_play.
  ///
  /// In en, this message translates to:
  /// **'PLAY_STORE'**
  String get publish_store_play;

  /// No description provided for @publish_store_app.
  ///
  /// In en, this message translates to:
  /// **'APP_STORE'**
  String get publish_store_app;

  /// No description provided for @publish_store_publisher_profile.
  ///
  /// In en, this message translates to:
  /// **'Store Publisher Profile'**
  String get publish_store_publisher_profile;

  /// No description provided for @publish_developer_name.
  ///
  /// In en, this message translates to:
  /// **'Developer name'**
  String get publish_developer_name;

  /// No description provided for @publish_developer_email.
  ///
  /// In en, this message translates to:
  /// **'Developer email'**
  String get publish_developer_email;

  /// No description provided for @publish_privacy_policy_url.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy URL'**
  String get publish_privacy_policy_url;

  /// No description provided for @publish_profiles_required_hint.
  ///
  /// In en, this message translates to:
  /// **'Owners can’t submit publish requests unless this is configured.'**
  String get publish_profiles_required_hint;

  /// No description provided for @publish_seeded_success.
  ///
  /// In en, this message translates to:
  /// **'Seeded '**
  String get publish_seeded_success;

  /// No description provided for @publish_seed_failed.
  ///
  /// In en, this message translates to:
  /// **'Seed failed'**
  String get publish_seed_failed;

  /// No description provided for @ai_label.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai_label;

  /// No description provided for @ai_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get ai_enabled;

  /// No description provided for @ai_disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get ai_disabled;

  /// No description provided for @ai_owner_setting_title.
  ///
  /// In en, this message translates to:
  /// **'Owner AI'**
  String get ai_owner_setting_title;

  /// No description provided for @ai_owner_setting_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable AI for this owner.'**
  String get ai_owner_setting_subtitle;

  /// No description provided for @ai_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading AI status…'**
  String get ai_loading;

  /// No description provided for @ai_update_success.
  ///
  /// In en, this message translates to:
  /// **'AI updated'**
  String get ai_update_success;

  /// No description provided for @ai_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update AI'**
  String get ai_update_failed;

  /// No description provided for @ai_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load AI status'**
  String get ai_load_failed;

  /// No description provided for @ownerAppsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search apps…'**
  String get ownerAppsSearchHint;

  /// No description provided for @ownerAppsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No apps found for this owner'**
  String get ownerAppsEmpty;

  /// No description provided for @ownerAppsUnnamed.
  ///
  /// In en, this message translates to:
  /// **'(Unnamed App)'**
  String get ownerAppsUnnamed;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @ownerAppsSlugStatus.
  ///
  /// In en, this message translates to:
  /// **'slug: {slug}  •  {status}'**
  String ownerAppsSlugStatus(String slug, String status);

  /// No description provided for @projectsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search projects…'**
  String get projectsSearchHint;

  /// No description provided for @projectsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get projectsEmpty;

  /// No description provided for @common_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get common_language;

  /// No description provided for @common_system_language.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get common_system_language;

  /// No description provided for @lang_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get lang_english;

  /// No description provided for @lang_arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get lang_arabic;

  /// No description provided for @lang_french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get lang_french;

  /// No description provided for @owner_publish_err_load_draft.
  ///
  /// In en, this message translates to:
  /// **'Failed to load publish draft'**
  String get owner_publish_err_load_draft;

  /// No description provided for @owner_publish_err_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get owner_publish_err_save_failed;

  /// No description provided for @owner_publish_err_submit_failed.
  ///
  /// In en, this message translates to:
  /// **'Submit failed'**
  String get owner_publish_err_submit_failed;

  /// No description provided for @owner_publish_err_logo_required.
  ///
  /// In en, this message translates to:
  /// **'Logo is required'**
  String get owner_publish_err_logo_required;

  /// No description provided for @owner_publish_country_us.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get owner_publish_country_us;

  /// No description provided for @owner_publish_country_lb.
  ///
  /// In en, this message translates to:
  /// **'Lebanon'**
  String get owner_publish_country_lb;

  /// No description provided for @owner_publish_country_fr.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get owner_publish_country_fr;

  /// No description provided for @owner_publish_upload_assets.
  ///
  /// In en, this message translates to:
  /// **'Upload Assets (Icon + Screenshots)'**
  String get owner_publish_upload_assets;

  /// No description provided for @owner_publish_current_icon.
  ///
  /// In en, this message translates to:
  /// **'Current Icon'**
  String get owner_publish_current_icon;

  /// No description provided for @owner_publish_no_icon_yet.
  ///
  /// In en, this message translates to:
  /// **'No icon uploaded yet.'**
  String get owner_publish_no_icon_yet;

  /// No description provided for @owner_publish_current_screenshots.
  ///
  /// In en, this message translates to:
  /// **'Current Screenshots'**
  String get owner_publish_current_screenshots;

  /// No description provided for @owner_publish_no_screenshots_yet.
  ///
  /// In en, this message translates to:
  /// **'No screenshots uploaded yet.'**
  String get owner_publish_no_screenshots_yet;

  /// No description provided for @owner_publish_rule_shots_2_8.
  ///
  /// In en, this message translates to:
  /// **'Rule: screenshots must be 2..8 before submitting.'**
  String get owner_publish_rule_shots_2_8;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// No description provided for @common_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get common_copy;

  /// No description provided for @common_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get common_share;

  /// No description provided for @common_uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get common_uploading;

  /// No description provided for @common_network_error_try_again.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get common_network_error_try_again;

  /// No description provided for @owner_publish_assets_title_android.
  ///
  /// In en, this message translates to:
  /// **'Android Assets'**
  String get owner_publish_assets_title_android;

  /// No description provided for @owner_publish_assets_title_ios.
  ///
  /// In en, this message translates to:
  /// **'iOS Assets'**
  String get owner_publish_assets_title_ios;

  /// No description provided for @owner_publish_assets_app_icon.
  ///
  /// In en, this message translates to:
  /// **'App Icon'**
  String get owner_publish_assets_app_icon;

  /// No description provided for @owner_publish_assets_choose_icon.
  ///
  /// In en, this message translates to:
  /// **'Choose Icon'**
  String get owner_publish_assets_choose_icon;

  /// No description provided for @owner_publish_assets_remove_icon.
  ///
  /// In en, this message translates to:
  /// **'Remove icon'**
  String get owner_publish_assets_remove_icon;

  /// No description provided for @owner_publish_assets_screenshots_2_8.
  ///
  /// In en, this message translates to:
  /// **'Screenshots (2..8)'**
  String get owner_publish_assets_screenshots_2_8;

  /// No description provided for @owner_publish_assets_no_screenshots.
  ///
  /// In en, this message translates to:
  /// **'No screenshots selected yet.'**
  String get owner_publish_assets_no_screenshots;

  /// No description provided for @owner_publish_assets_upload_assets.
  ///
  /// In en, this message translates to:
  /// **'Upload Assets'**
  String get owner_publish_assets_upload_assets;

  /// No description provided for @owner_publish_assets_uploaded.
  ///
  /// In en, this message translates to:
  /// **'Assets uploaded ✅'**
  String get owner_publish_assets_uploaded;

  /// No description provided for @owner_publish_assets_err_pick_icon_or_screens.
  ///
  /// In en, this message translates to:
  /// **'Pick an icon OR screenshots first'**
  String get owner_publish_assets_err_pick_icon_or_screens;

  /// No description provided for @owner_publish_assets_err_screens_min2.
  ///
  /// In en, this message translates to:
  /// **'Screenshots: add at least 2'**
  String get owner_publish_assets_err_screens_min2;

  /// No description provided for @owner_publish_assets_err_screens_max8.
  ///
  /// In en, this message translates to:
  /// **'Screenshots: maximum 8 allowed'**
  String get owner_publish_assets_err_screens_max8;

  /// No description provided for @owner_project_err_no_link_open.
  ///
  /// In en, this message translates to:
  /// **'No link to open'**
  String get owner_project_err_no_link_open;

  /// No description provided for @owner_project_err_invalid_url.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get owner_project_err_invalid_url;

  /// No description provided for @owner_project_err_cannot_open.
  ///
  /// In en, this message translates to:
  /// **'Cannot open'**
  String get owner_project_err_cannot_open;

  /// No description provided for @owner_project_err_no_link_copy.
  ///
  /// In en, this message translates to:
  /// **'No link to copy'**
  String get owner_project_err_no_link_copy;

  /// No description provided for @owner_project_err_no_link_share.
  ///
  /// In en, this message translates to:
  /// **'No link to share'**
  String get owner_project_err_no_link_share;

  /// No description provided for @owner_project_err_share_failed.
  ///
  /// In en, this message translates to:
  /// **'Share failed'**
  String get owner_project_err_share_failed;

  /// No description provided for @owner_project_link_copied.
  ///
  /// In en, this message translates to:
  /// **'Link copied ✅'**
  String get owner_project_link_copied;

  /// No description provided for @owner_project_status_active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get owner_project_status_active;

  /// No description provided for @owner_project_status_in_production.
  ///
  /// In en, this message translates to:
  /// **'IN_PRODUCTION'**
  String get owner_project_status_in_production;

  /// No description provided for @owner_project_android.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get owner_project_android;

  /// No description provided for @owner_project_ios.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get owner_project_ios;

  /// No description provided for @owner_project_apk.
  ///
  /// In en, this message translates to:
  /// **'APK'**
  String get owner_project_apk;

  /// No description provided for @owner_project_aab.
  ///
  /// In en, this message translates to:
  /// **'AAB'**
  String get owner_project_aab;

  /// No description provided for @owner_project_ipa.
  ///
  /// In en, this message translates to:
  /// **'IPA'**
  String get owner_project_ipa;

  /// No description provided for @owner_project_play_not_requested.
  ///
  /// In en, this message translates to:
  /// **'Play Store: Not Requested'**
  String get owner_project_play_not_requested;

  /// No description provided for @owner_project_appstore_not_requested.
  ///
  /// In en, this message translates to:
  /// **'App Store: Not Requested'**
  String get owner_project_appstore_not_requested;

  /// No description provided for @owner_project_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get owner_project_ready;

  /// No description provided for @owner_project_building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get owner_project_building;

  /// No description provided for @owner_project_download_section.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD'**
  String get owner_project_download_section;

  /// No description provided for @owner_project_publish_section.
  ///
  /// In en, this message translates to:
  /// **'PUBLISH'**
  String get owner_project_publish_section;

  /// No description provided for @owner_project_share_ios.
  ///
  /// In en, this message translates to:
  /// **'Download {appName} iOS (IPA)'**
  String owner_project_share_ios(Object appName);

  /// No description provided for @owner_project_share_android.
  ///
  /// In en, this message translates to:
  /// **'Download {appName} Android ({format})'**
  String owner_project_share_android(Object appName, Object format);

  /// No description provided for @owner_project_ios_testflight_hint.
  ///
  /// In en, this message translates to:
  /// **'Installez TestFlight pour ouvrir l’application'**
  String get owner_project_ios_testflight_hint;

  /// No description provided for @owner_project_android_download_hint.
  ///
  /// In en, this message translates to:
  /// **'Télécharger pour installer :'**
  String get owner_project_android_download_hint;

  /// No description provided for @errPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get errPhoneRequired;

  /// No description provided for @errPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Phone number is invalid'**
  String get errPhoneInvalid;

  /// No description provided for @lblPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get lblPhone;

  /// No description provided for @hintPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get hintPhone;

  /// No description provided for @alreadyHaveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccountLogin;

  /// No description provided for @owner_profile_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get owner_profile_phone;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @owner_project_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get owner_project_failed;

  /// No description provided for @owner_project_build_failed.
  ///
  /// In en, this message translates to:
  /// **'Build failed'**
  String get owner_project_build_failed;

  /// No description provided for @owner_project_play_store.
  ///
  /// In en, this message translates to:
  /// **'Play Store:'**
  String get owner_project_play_store;

  /// No description provided for @owner_project_app_store.
  ///
  /// In en, this message translates to:
  /// **'App Store:'**
  String get owner_project_app_store;

  /// No description provided for @owner_project_requested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get owner_project_requested;

  /// No description provided for @owner_project_not_requested.
  ///
  /// In en, this message translates to:
  /// **'Not Requested'**
  String get owner_project_not_requested;

  /// No description provided for @owner_project_download.
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get owner_project_download;

  /// No description provided for @owner_project_open.
  ///
  /// In en, this message translates to:
  /// **'Download TestFlight to open'**
  String get owner_project_open;

  /// No description provided for @owner_project_retry_build.
  ///
  /// In en, this message translates to:
  /// **'Retry Build'**
  String get owner_project_retry_build;

  /// No description provided for @owner_project_publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get owner_project_publish;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
