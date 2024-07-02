import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:meal_tracker_app/Provider/match_data_provider.dart';
import 'package:meal_tracker_app/Screens/add_meal_screen.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../Models/Colors.dart';

class RecipeScreen extends StatefulWidget {
  String? calories;
  double? val;
  RecipeScreen({this.calories, this.val, Key? key}) : super(key: key);

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen>
    with SingleTickerProviderStateMixin {
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final Stream<QuerySnapshot<Map<String, dynamic>>> mealStream =
      FirebaseFirestore.instance
          .collection("addMealData")
          .where('current_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          // .orderBy('create_time', descending: true)
          .snapshots();
  CollectionReference addnewmeal =
      FirebaseFirestore.instance.collection('addMealData');

  bool isLoading = false;
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );

  late final Animation<Offset> _listAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(1.5, 0.0),
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticIn,
  ));
  final mealNameController = TextEditingController();
  final categoryController = TextEditingController();
  
  @override
  void initState() {
    repeatOnce();
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if(mounted){
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  void repeatOnce() async {
    await _controller.forward();
    await _controller.reverse();
  }

  Future<void> updateMeal(id) {
    return FirebaseFirestore.instance.collection("addMealData").doc(id).update({
      'meal_name': mealNameController.text.trim(),
      'create_time': Provider.of<Matchdate>(context, listen: false).datestore,
    }).then((value) => Navigator.pop(context));
  }

  DateTime _focusDay = DateTime.now();
  DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      _focusDay = day;
    });
    Provider.of<Matchdate>(context, listen: false)
        .storeDate(dateFormat.format(_focusDay));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.green.shade50 : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        systemOverlayStyle:
            SystemUiOverlayStyle(statusBarColor: Theme.of(context).brightness == Brightness.light ? Colors.green.shade200 : Colors.black,
            ),
        elevation: 0,
        backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.green.shade50 : Theme.of(context).scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Text("Meal Planner",
              style: GoogleFonts.anekOdia(
                  textStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light ? MyColors.darkGreen : Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold))),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: mealStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Column(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0, top: 100.0),
                      child: Lottie.asset('assets/foddloading.json',
                          height: 200, width: 200),
                    ),
                  ),
                  Text(
                    "Foraging Best Recipes",
                    style: GoogleFonts.kalam(
                      textStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light ? MyColors.darkGreen : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              );
            } else if (snapshot.hasError) {
              print("Something went wrong");
              return Column(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0, top: 100.0),
                      child: Lottie.asset('assets/foddloading.json',
                          height: 200, width: 200),
                    ),
                  ),
                  Text(
                    "Foraging Best Recipes",
                    style: GoogleFonts.kalam(
                      textStyle: const TextStyle(
                          color: MyColors.darkGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.light ? Colors.white: Colors.black,
                            borderRadius: BorderRadius.circular(20)),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2000, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusDay,
                          availableCalendarFormats: const {
                            CalendarFormat.week: 'Week',
                          },
                          calendarFormat: CalendarFormat.week,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          rowHeight: 60,
                          daysOfWeekHeight: 40,
                          selectedDayPredicate: (day) =>
                              isSameDay(day, _focusDay),
                          onDaySelected: _onDaySelected,
                          headerStyle: HeaderStyle(
                              titleCentered: true,
                              formatButtonVisible: false,
                              titleTextStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.light ? MyColors.darkGreen : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                          ),
                          calendarBuilders: CalendarBuilders(
                              dowBuilder: (context, dayOfWeek) {
                            return Center(
                              child: Container(
                                width: 40,
                                decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  DateFormat.E()
                                      .format(dayOfWeek)
                                      .substring(0, 3),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.mukta(
                                      color: MyColors.darkGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1),
                                ),
                              ),
                            );
                          }),
                          calendarStyle: CalendarStyle(
                              defaultDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white60,
                              ),
                              outsideDecoration: BoxDecoration(
                                color: Colors.white60,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              weekendDecoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              todayDecoration: BoxDecoration(
                                color: Colors.green.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              weekendTextStyle:
                                  const TextStyle(color: Colors.red),
                              selectedDecoration: BoxDecoration(
                                color: MyColors.darkGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              outsideDaysVisible: false),
                        ),
                      ),
                    ),
                    Consumer<Matchdate>(
                      builder: (context, md, _) {
                        List<DocumentSnapshot<Map<String, dynamic>>> meals = snapshot.data!.docs.where((meal) {
                          String? mealDate = meal.get("create_time");
                          return mealDate != null && mealDate == dateFormat.format(_focusDay).toString();
                        }).toList();
                        print('Current User ID: $currentUserId');

                        if (meals.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(28.0),
                            child: Center(
                              child: Text(
                                "Meal not added yet",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: meals.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> mealData = meals[index].data()!;
                            print('Meal Data: $mealData');

                            return Dismissible(
                              key: UniqueKey(),
                              background: Container(
                                decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.only(left: 28.0),
                                alignment: AlignmentDirectional.centerStart,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              direction: DismissDirection.startToEnd,
                              onDismissed: (direction) async {
                                await FirebaseFirestore.instance.runTransaction(
                                    (Transaction myTransaction) async {
                                  await myTransaction.delete(
                                      snapshot.data!.docs[index].reference);
                                });
                              },
                              child: Container(
                                height: 110,
                                margin: const EdgeInsets.only(
                                    bottom: 10, left: 10, right: 10),
                                decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.light ? Colors.white: Colors.black,
                                    borderRadius: BorderRadius.circular(20)),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      'assets/images/${Random().nextInt(5) + 1}.jpg',
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(mealData['meal_name'] ?? "",
                                      style: GoogleFonts.abhayaLibre(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  subtitle: Text(mealData['category'] ?? ""),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          mealNameController.text =
                                              mealData['meal_name'] ?? "";
                                          categoryController.text =
                                              mealData['category'] ?? "";

                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.green.shade100 : Colors.black,
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      TextField(
                                                        controller:
                                                            mealNameController,
                                                        decoration:
                                                            const InputDecoration(
                                                                labelText:
                                                                    'Meal Name'),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            categoryController,
                                                        decoration:
                                                            const InputDecoration(
                                                                labelText:
                                                                    'Category'),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: const Text(
                                                            'Cancel')),
                                                    TextButton(
                                                        onPressed: () async {
                                                          updateMeal(meals[index].id);
                                                          setState(() {
                                                            isLoading = true;
                                                          });
                                                          Future.delayed(const Duration(seconds: 3), () {
                                                            if(mounted){
                                                              setState(() {
                                                                isLoading = false;
                                                              });
                                                            }
                                                          });
                                                        },
                                                        child: const Text(
                                                            'Update'))
                                                  ],
                                                );
                                              });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance.runTransaction(
                                              (Transaction myTransaction) async {
                                            await myTransaction.delete(snapshot.data!.docs[index].reference);
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            }
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => AddMealScreen()));
        },
        backgroundColor: Theme.of(context).brightness == Brightness.light ? MyColors.darkGreen: Colors.green.shade50,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
