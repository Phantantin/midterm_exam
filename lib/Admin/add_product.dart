import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:midterm_exam/services/database.dart';
import 'package:midterm_exam/widget/support_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:random_string/random_string.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  String? imageUrl; // URL của ảnh sản phẩm khi bấm sửa
  TextEditingController namecontroller = TextEditingController();
  TextEditingController pricecontroller = TextEditingController();
  TextEditingController typecontroller = TextEditingController();
  String? editProductId; // ID của sản phẩm đang chỉnh sửa

  Future<void> requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
  }

  Future<void> getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
        imageUrl = null; // Reset URL của ảnh cũ khi chọn ảnh mới
      });
    }
  }

  Future<void> uploadItem() async {
    if ((selectedImage != null || imageUrl != null) &&
        namecontroller.text.isNotEmpty) {
      String addId = editProductId ?? randomAlphaNumeric(10);
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child("blogImage").child(addId);

      if (selectedImage != null) {
        UploadTask task = firebaseStorageRef.putFile(selectedImage!);
        imageUrl = await (await task).ref.getDownloadURL();
      }

      Map<String, dynamic> addProduct = {
        "Name": namecontroller.text,
        "Image": imageUrl,
        "Price": pricecontroller.text,
        "Type": typecontroller.text,
      };

      if (editProductId == null) {
        await DatabaseMethods().addAllProducts(addProduct);
      } else {
        await FirebaseFirestore.instance
            .collection('Products')
            .doc(editProductId)
            .update(addProduct);
      }

      setState(() {
        selectedImage = null;
        namecontroller.clear();
        pricecontroller.clear();
        typecontroller.clear();
        imageUrl = null;
        editProductId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Product has been uploaded Successfully!!",
            style: TextStyle(fontSize: 20.0),
          )));
    }
  }

  // Function to delete product with confirmation
  Future<void> deleteProduct(String docId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn xóa sản phẩm này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      FirebaseFirestore.instance.collection('Products').doc(docId).delete();
    }
  }

  // Function to load product information into text fields and display image
  void editProduct(QueryDocumentSnapshot product) {
    setState(() {
      namecontroller.text = product['Name'];
      pricecontroller.text = product['Price'];
      typecontroller.text = product['Type'];
      imageUrl =
          product['Image']; // Load URL ảnh của sản phẩm vào biến imageUrl
      selectedImage =
          null; // Reset selectedImage nếu người dùng muốn chọn ảnh mới
      editProductId = product.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new_outlined)),
        title: Center(
          child: Text(
            "Add Product",
            style: AppWidget.semiboldTextFeildStyle(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin:
              EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0, bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upload Image Section
              Text(
                "Upload the Product Image",
                style: AppWidget.lightTextFeildStyle(),
              ),
              SizedBox(height: 20.0),

              // Hiển thị ảnh sản phẩm khi bấm sửa hoặc ảnh đã chọn từ thư viện
              GestureDetector(
                onTap: getImage,
                child: Center(
                  child: selectedImage == null && imageUrl != null
                      ? Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(20),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                  height: 150,
                                  width: 150,
                                  child: Image.network(imageUrl!,
                                      fit: BoxFit.cover))),
                        )
                      : selectedImage != null
                          ? Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(20),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                      height: 150,
                                      width: 150,
                                      child: Image.file(selectedImage!,
                                          fit: BoxFit.cover))),
                            )
                          : Container(
                              height: 150,
                              width: 150,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black, width: 1.5),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Icon(Icons.camera_alt_outlined),
                            ),
                ),
              ),

              SizedBox(height: 20.0),
              // Input Fields
              Text("Product Name", style: AppWidget.lightTextFeildStyle()),
              SizedBox(height: 20.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(20)),
                child: TextField(
                  controller: namecontroller,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              SizedBox(height: 20.0),
              Text("Product Price", style: AppWidget.lightTextFeildStyle()),
              SizedBox(height: 20.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(20)),
                child: TextField(
                  controller: pricecontroller,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              SizedBox(height: 20.0),
              Text("Product Type", style: AppWidget.lightTextFeildStyle()),
              SizedBox(height: 20.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(20)),
                child: TextField(
                  controller: typecontroller,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              SizedBox(height: 30.0),
              Center(
                child: ElevatedButton(
                    onPressed: () {
                      uploadItem();
                    },
                    child: Text(
                      editProductId == null ? "Add Product" : "Update Product",
                      style: TextStyle(fontSize: 22.0),
                    )),
              ),
              SizedBox(height: 30.0),

              // Product List Section
              Center(
                  child: Text(
                "Danh sách sản phẩm",
                style:
                    AppWidget.semiboldTextFeildStyle().copyWith(fontSize: 30),
              )),
              SizedBox(height: 20),

              // Display product list using StreamBuilder
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('Products')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Something went wrong!'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var product = snapshot.data!.docs[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: ListTile(
                          leading: Image.network(
                            product['Image'],
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                          ),
                          title: Text(product['Name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Price: " + product['Price']),
                              Text("Type: " + product['Type']),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                color: Colors.green,
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  editProduct(product);
                                },
                              ),
                              IconButton(
                                color: Colors.red,
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  deleteProduct(product.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
