import 'package:cart_stepper/cart_stepper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:custom_radio_grouped_button/custom_radio_grouped_button.dart';

var db = FirebaseFirestore.instance;
String categoryCollectionName = 'cafe-category';
String itemCollectionName = 'cafe-item';

void main() async {
  await Firebase.initializeApp(
    // 다쓸 수 있다.(싱글톤)
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: false),
      debugShowCheckedModeBanner: false,
      home: const Main(),
    );
  }
}

// 진짜 페이지
class Main extends StatefulWidget {
  const Main({
    super.key,
  });

  @override
  State<Main> createState() => _MainState();
}

// 진입점
class _MainState extends State<Main> {
  dynamic categoryList = const Text('category');
  dynamic itemList = const Text('item');
  PanelController panelController = PanelController(); //장바구니 컨르롤러

  String toCurrency(int n) {
    return NumberFormat.currency(locale: "ko_KR", symbol: "₩").format(n);
    // 위에는 선생님이 한 형식
    // return NumberFormat.simpleCurrency(
    //   locale: "ko_KR",
    //   name: "",
    //   decimalDigits: 0,
    // ).format(n);
  }

  // 카테고리 보기 기능
  Future<void> showCategoryList() async {
    var result = db
        .collection(categoryCollectionName)
        .get(); // <- JsonQuerySnapshot type임
    // var datas = result.docs; // 변환

    categoryList = FutureBuilder(
      future: result,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var datas = snapshot.data!.docs;
          if (datas.isEmpty) {
            return const Text('nothing');
          } else {
            return CustomRadioButton(
              enableButtonWrap: true,
              wrapAlignment: WrapAlignment.start,
              elevation: 0,
              absoluteZeroSpacing: true,
              defaultSelected: 'toAll',
              unSelectedColor: Theme.of(context).canvasColor,
              buttonLables: [
                '전체보기',
                for (var data in datas) data['categoryName']
              ],
              buttonValues: [
                'toAll',
                for (var data in datas) data.id,
              ],
              buttonTextStyle: const ButtonTextStyle(
                  selectedColor: Colors.white,
                  unSelectedColor: Colors.black,
                  textStyle: TextStyle(fontSize: 16)),
              radioButtonValue: (value) {
                showItems(value);
              },
              selectedColor: Theme.of(context).colorScheme.secondary,
            );
          }
        } else {
          return const Text('loading...');
        }
      },
    );
  }

  // 아이템 보기 기능
  Future<void> showItems(String value) async {
    // value(categoryId)를 갖고 있는 아이템들을 출력
    setState(() {
      itemList = FutureBuilder(
        future: value != 'toAll'
            ? db
                .collection(itemCollectionName)
                .where('categoryId', isEqualTo: value)
                .get()
            : db.collection(itemCollectionName).get(),
        builder: (context, snapshot) {
          if (snapshot.hasData == true) {
            var items = snapshot.data!.docs;
            if (items.isEmpty) {
              // 아이템이 존재하지 않을 경우
              return const Center(child: Text('empty'));
            } else {
              // 아이템이 존재하는 경우
              List<Widget> lt = [];
              for (var item in items) {
                lt.add(GestureDetector(
                  onTap: () {
                    int cnt = 1;
                    int price = item['itemPrice'];
                    List<dynamic> options = item['options'];
                    List<Widget> datas = [];
                    for (var option in options) {
                      var values = option['optionValue'].toString().split('\n');
                      datas.add(ListTile(
                          title: Text(option['optionName']),
                          subtitle: CustomRadioButton(
                            enableButtonWrap: true,
                            wrapAlignment: WrapAlignment.start,
                            buttonLables: values,
                            buttonValues: values,
                            radioButtonValue: (p0) {
                              print(p0);
                            },
                            unSelectedColor: Colors.white,
                            selectedColor: Colors.teal,
                          )));
                    }
                    showDialog(
                      context: context,
                      builder: (context) =>
                          StatefulBuilder(builder: (context, st) {
                        return AlertDialog(
                          title: ListTile(
                              title: Text('${item['itemName']}'),
                              subtitle: Text(toCurrency(price)),
                              trailing: CartStepper(
                                value: cnt,
                                stepper: 1,
                                didChangeCount: (value) {
                                  if (value > 0) {
                                    st(() {
                                      cnt = value;
                                      price = item['itemPrice'] * cnt;
                                    });
                                  }
                                },
                              )),
                          content: Column(
                            children: datas,
                          ),
                          actions: const [
                            Text('취소'),
                            Text('담기'),
                          ],
                        );
                      }),
                    );
                  },
                  child: Container(
                    width: 150,
                    height: 150,
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.black),
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(item['itemName']),
                        Text(toCurrency(item['itemPrice']))
                      ],
                    ),
                  ),
                ));
              }
              return Wrap(
                alignment: WrapAlignment.spaceAround,
                children: lt,
              );
            }
          } else {
            // 데이터 로드 중
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    });
  }
  // 장바구니 기능

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    showCategoryList();
    showItems('toAll');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('bbungka coffee'),
        actions: [
          Transform.translate(
            offset: const Offset(-10, 10),
            child: Badge(
              label: const Text('1'), // 장바구니 개수
              child: IconButton(
                  onPressed: () {
                    if (panelController.isPanelClosed) {
                      panelController.open();
                    } else {
                      panelController.close();
                    }
                  },
                  icon: const Icon(
                    Icons.shopping_cart,
                  )),
            ),
          )
        ],
      ),
      body: SlidingUpPanel(
        controller: panelController,
        minHeight: 50,
        maxHeight: 500,
        // 장바구니 슬라이딩
        panel: Container(
          color: Colors.amber,
        ),
        body: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            // 카테고리 목록
            categoryList,
            // 아이템
            Expanded(child: itemList),
          ],
        ),
      ),
    );
  }
}
