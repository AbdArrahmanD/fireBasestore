import 'package:firestoretest/pages/splashScreen.dart';
import 'package:firestoretest/providers/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/add_products.dart';
import 'pages/auth_screen.dart';
import 'pages/product_details.dart';
import 'providers/products.dart';
import 'providers/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Auth>(
          create: (_) => Auth(),
        ),
        ChangeNotifierProxyProvider<Auth, Products>(
          create: (_) => Products(),
          update: (context, value, lastValue) => lastValue!
            ..getData(
              value.token,
              lastValue.productsList,
            ),
        )
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Colors.orange,
          canvasColor: Color.fromRGBO(255, 238, 219, 1)),
      debugShowCheckedModeBanner: false,
      home: Provider.of<Auth>(context).isAuth
          ? MyHomePage()
          : FutureBuilder(
              future: Provider.of<Auth>(context, listen: false).tryAutoLogin(),
              builder: (context, snapShot) {
                if (snapShot.connectionState == ConnectionState.done) {
                  return AuthScreen();
                } else {
                  return MySplashScreen();
                }
              }),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    try {
      Provider.of<Products>(context, listen: false)
          .fetchData()
          .then((_) => _isLoading = false);
    } catch (e) {
      print(e);
    }

    super.initState();
  }

  Widget detailCard(id, title, desc, price, imageUrl) {
    return Builder(
      builder: (innerContext) => TextButton(
        onPressed: () {
          print(id);
          Navigator.push(
            innerContext,
            MaterialPageRoute(builder: (_) => ProductDetails(id)),
          ).then((id) => id != null
              ? Provider.of<Products>(context, listen: false).delete(id)
              : null);
        },
        child: Column(
          children: [
            SizedBox(height: 5),
            Card(
              elevation: 10,
              color: Color.fromRGBO(115, 138, 119, 1),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.only(right: 10),
                      width: 130,
                      child: Hero(
                        tag: id,
                        child: Image.network(imageUrl, fit: BoxFit.fill),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(height: 10),
                        Text(
                          title,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        Divider(color: Colors.white),
                        Container(
                          width: 200,
                          child: Text(
                            desc,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            softWrap: true,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.justify,
                            maxLines: 3,
                          ),
                        ),
                        Divider(color: Colors.white),
                        Text(
                          "\$$price",
                          style: TextStyle(color: Colors.black, fontSize: 18),
                        ),
                        SizedBox(height: 13),
                      ],
                    ),
                  ),
                  Expanded(flex: 1, child: Icon(Icons.arrow_forward_ios)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Product?> prodList =
        Provider.of<Products>(context, listen: true).productsList;
    print('prodList is : $prodList');
    return Scaffold(
      appBar: AppBar(
        title: Text('My Products'),
        actions: [
          TextButton(
            onPressed: () => Provider.of<Auth>(context, listen: false).logout(),
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 20, 0, 0),
                child: Container(
                  width: double.infinity,
                  child: const Text(
                    'My App',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              child: Card(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : (prodList.isEmpty
              ? Center(
                  child: Text('No Products Added.',
                      style: TextStyle(fontSize: 22)))
              : RefreshIndicator(
                  onRefresh: () async =>
                      await Provider.of<Products>(context, listen: false)
                          .fetchData(),
                  child: ListView(
                    children: prodList
                        .map(
                          (item) => detailCard(item?.id, item?.title,
                              item?.description, item?.price, item?.imageUrl),
                        )
                        .toList(),
                  ),
                )),
      floatingActionButton: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: Theme.of(context).primaryColor,
        ),
        child: TextButton.icon(
          label: Text("Add Product",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: Colors.black)),
          icon: Icon(Icons.add),
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => AddProduct())),
        ),
      ),
    );
  }
}
