import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// 주문저장, 주문번호, 시간이 지나면 다시 메인으로 이동
class OrderResult extends StatefulWidget {
  Map<String, dynamic> orderResult;
  OrderResult({super.key, required this.orderResult});

  @override
  State<OrderResult> createState() => _OrderResultState();
}

class _OrderResultState extends State<OrderResult> {
  late Map<String, dynamic> orderResult;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    orderResult = widget.orderResult;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text(orderResult.toString()),
    );
  }
}
