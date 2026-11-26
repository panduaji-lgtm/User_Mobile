export 'package:app/features/auth/data/models/auth_models.dart'
    show
        GoogleAuthCancelledException,
        GoogleAuthConfigException,
        GoogleAuthCredential;
export 'google_auth_client_mobile.dart'
    if (dart.library.js_interop) 'google_auth_client_web.dart';
