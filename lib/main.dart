import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

String baseCurrencyUrl =
    'https://api.freecurrencyapi.com/v1/latest?apikey=ZGjkuJ6CfUw0p9T3lndiwokk5QB0WpNpovsxfuzk';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String fromCurrency = 'USD';
  String toCurrency = '';
  bool isLoading = false;
  Map<String, double> rates = {};

  double result = 0;

  double convert(String from, String to, double amount) {
    double fromRate = rates[from]!;
    double toRate = rates[to]!;

    return (amount / fromRate) * toRate;
  }

  void fetchCurrencyData() async {
    setState(() {
      isLoading = true;
    });

    Uri url = Uri.parse(baseCurrencyUrl);

    Response result = await get(url);

    Map<String, dynamic> parsed =
        (jsonDecode(result.body) as Map)['data'] as Map<String, dynamic>;

    setState(() {
      isLoading = false;
      rates = parsed
          .map((key, value) => MapEntry(key, double.parse(value.toString())));
      // Sort the rates from least amount of rate to the largest.
      rates = Map.fromEntries(rates.entries.toList()
        ..sort((e1, e2) => e1.value.compareTo(e2.value)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(brightness: Brightness.dark),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Currency Conversion App')),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (toCurrency.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text('FROM'),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade900,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Amount',
                              isDense: true,
                              border: InputBorder.none,
                              suffix: Text(fromCurrency),
                            ),
                            onChanged: (value) {
                              if (value.isEmpty) {
                                setState(() => result = 0);
                                return;
                              }

                              setState(() {
                                result = convert(fromCurrency, toCurrency,
                                    double.parse(value));
                              });
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]')),
                              TextInputFormatter.withFunction(
                                  (oldValue, newValue) {
                                if (newValue.text.isEmpty) {
                                  return newValue;
                                }

                                if (double.tryParse(newValue.text) == null) {
                                  return oldValue;
                                }

                                return newValue;
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: fromCurrency,
                        onChanged: (String? newValue) =>
                            setState(() => fromCurrency = newValue!),
                        items: rates.keys.map((String e) {
                          return DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          );
                        }).toList(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade900,
                          ),
                          padding: const EdgeInsets.all(15),
                          child:
                              Text('${result.toStringAsFixed(2)} $toCurrency'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (rates.isNotEmpty) ...[
                const SizedBox(height: 10, width: double.infinity),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text('TO'),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: rates.keys.map((e) {
                      final String name = e;
                      final double? rate = rates[e];

                      return InkWell(
                        onTap: () => setState(() {
                          if (toCurrency == name) {
                            toCurrency = '';
                          } else {
                            toCurrency = name;
                          }
                        }),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade900,
                            border: toCurrency == name
                                ? Border.all(color: Colors.teal, width: 2)
                                : null,
                          ),
                          width: 150,
                          height: 60,
                          child: Stack(
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: Text(
                                  rate!.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (rates.isEmpty)
                Center(
                  child: TextButton(
                    onPressed: () {
                      fetchCurrencyData();
                    },
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Fetch Currency Data'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
