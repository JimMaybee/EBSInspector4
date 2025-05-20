import 'dart:io';

import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:flutter/foundation.dart';

final firebaseOptions = kIsWeb ? firebaseOptionsWeb : (Platform.isIOS ? firebaseOptionsiOS : firebaseOptionsAndroid);

final firebaseOptionsWeb = firebase_core.FirebaseOptions(
  apiKey: "AIzaSyDoqsTfKnO1fuvVVCGvLZCbgYedKN2JgjQ",
  appId: "1:118532743817:web:16b2a291ec12de93285c58",
  authDomain: "ebs-inspector-2.firebaseapp.com",
  databaseURL: "https://ebs-inspector-2.firebaseio.com",
  measurementId: "G-4JHKB0BRGR",
  messagingSenderId: "118532743817",
  projectId: "ebs-inspector-2",
  storageBucket: "ebs-inspector-2.appspot.com",
);

final firebaseOptionsAndroid = firebase_core.FirebaseOptions(
  apiKey: "AIzaSyDoqsTfKnO1fuvVVCGvLZCbgYedKN2JgjQ",
  appId: "1:118532743817:android:daef8901c009e3e5285c58",
  authDomain: "ebs-inspector-2.firebaseapp.com",
  databaseURL: "https://ebs-inspector-2.firebaseio.com",
  measurementId: "G-4JHKB0BRGR",
  messagingSenderId: "118532743817",
  projectId: "ebs-inspector-2",
  storageBucket: "ebs-inspector-2.appspot.com",
);

final firebaseOptionsiOS = firebase_core.FirebaseOptions(
  apiKey: "AIzaSyDoqsTfKnO1fuvVVCGvLZCbgYedKN2JgjQ",
  appId: "1:118532743817:ios:cbd5467046e118ea285c58",
  authDomain: "ebs-inspector-2.firebaseapp.com",
  databaseURL: "https://ebs-inspector-2.firebaseio.com",
  measurementId: "G-4JHKB0BRGR",
  messagingSenderId: "118532743817",
  projectId: "ebs-inspector-2",
  storageBucket: "ebs-inspector-2.appspot.com",
);
