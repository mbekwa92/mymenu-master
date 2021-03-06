
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mymenu/Models/ConfirmCheckOut.dart';
import 'package:mymenu/Models/FoodItem.dart';
import 'package:mymenu/Models/Order.dart';
import 'package:mymenu/Models/User.dart';


class Auth {
  //allows us to use firebase authentication -- line below

  final FirebaseAuth _auth = FirebaseAuth.instance;  //_ means private in variable auth

  String uid;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  //List<Order> orders = [Order(image: "https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__340.jpg",price: 0,food_id: "placeholder")];
  //create user object based on Firebase user
  List<ConfirmCheckOut> orders = [];
  // User _userFromFireBaseUser(FirebaseUser user){
  //   return user!=null ? User(userId: user.uid) : null;
  // }
  // auth change user stream

  bool showSignIn = true;





  Stream< FirebaseUser> get user{
    //tells us each time user signs in / out
    return _auth.onAuthStateChanged;
  }
  

  //sign in with email and password



  //sign out
  Future signOut() async{
    try{
      await _googleSignIn.signOut();
      return await _auth.signOut();

    }
    catch(e){
      print("________________________________no SIGN OUT $e");
      return null;

    }
  }

  //users connecting to database
  final CollectionReference orderCollection = Firestore.instance.collection("Orders");



  //CB and edit
  Future checkOutApproved(ConfirmCheckOut food, double promo,String indexPromo,String promoApplied) async{

    String uid = await inputData();
    DateTime date = DateTime.now();
    String time = date.toString();
    int index = time.indexOf('.');
    String timeUsed = time.substring(0,index);
    String mealOption = "";

    for(String option in food.mealOptions){
      mealOption+=option +",";
    }


    await Firestore.instance.collection("OrdersShops").document("OrdersShops").collection(food.shop).document(uid).setData({
      "$timeUsed": {
        'title': food.title,
        'mealOptions':mealOption,
        'price': food.price,
        'quantity': food.quantity,
        'active': 1,
        'user': uid,
        'date':date,
        'shopSeen':"No",
        'promo': promoApplied=="Yes" ? promo: 0

      }



    },merge: true);
    await Future.delayed(const Duration(seconds: 1), () => "1");
    if(promoApplied=="Yes") {
      indexPromo.isEmpty ? print(indexPromo) : await Firestore.instance.collection("Users").document(uid).updateData(
          {
            "promotions.$indexPromo.used": "Yes",
          });
    }

  
    return await Firestore.instance.collection("OrdersRefined").document(uid).updateData(
        {
          "${food.title}.checkOut": "Yes",
          "${food.title}.promo":promoApplied=="Yes" ? promo: 0
        });



  }

  List<ConfirmCheckOut> _ordersFromSnapshot(DocumentSnapshot snapshot) {
   orders = [];

    snapshot.data.keys.forEach((element) {

      try {

        if(snapshot[element]["active"]==1 && snapshot[element]["checkOut"]!="Yes"){

          orders.add(ConfirmCheckOut(
              title:snapshot[element]["title"],
              price:snapshot[element]["price"],
              quantity: snapshot[element]["quantity"],
              time: snapshot[element]["date"],
              shop:snapshot[element]["shop"],
              mealOptions: snapshot[element]["selectedOptions"] ?? []
          ));



        }
      }
      catch(e){
        print(e);
      }
    });



  return orders;

  }





  Stream<List<ConfirmCheckOut>> myOrders(String user) {
    //returns snapshot of database and tells us of any changes [provider]

    return Firestore.instance.collection("OrdersRefined").document(user).snapshots().map(_ordersFromSnapshot);
  }


  Future deleteFromDb(String id) async{
    String uid = await inputData();
    try {
      DocumentReference doc = Firestore.instance.collection("OrdersRefined")
          .document(uid);
       doc.updateData({ id: FieldValue.delete()});
    }
    catch(e){
      print(e);
      return null;
    }
  }

  Future inputData() async {
    final FirebaseUser user = await _auth.currentUser();

    return user.uid;
    // here you write the codes to input the data into firestore
  }


}