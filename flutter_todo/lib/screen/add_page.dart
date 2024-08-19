import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_todo/screen/todo_list.dart';
import 'package:http/http.dart' as http;

class AddPage extends StatefulWidget {
  final String userId;

  const AddPage({super.key, this.todo, required this.userId});
  final Map? todo;
  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  bool isEdit = false;
  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    if (todo != null) {
      isEdit = true;
      final title = todo['taskName'];
      final description = todo['description'];
      titleController.text = title;
      descriptionController.text = description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 40, 144, 255),
        title: Text(
          isEdit ? 'Edit todo' : 'Add todo',
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(238, 255, 254, 254)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: 'Title',
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(hintText: 'Description'),
            keyboardType: TextInputType.multiline,
            minLines: 5,
            maxLines: 8,
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: isEdit ? updateData : submitData,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 40, 144, 255)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                isEdit ? 'Update' : 'Submit',
                style: TextStyle(
                    fontSize: 20, color: Color.fromARGB(238, 255, 254, 254)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> updateData() async {
    final todo = widget.todo;
    if (todo == null) {
      print("No todo data ");
      return;
    }
    final title = titleController.text;
    final id = todo['_id'];
    final description = descriptionController.text;
    final body = {
      "taskName": title,
      "description": description,
    };
    //
    final url = 'http://localhost:5000/tasks/${widget.userId}/$id';
    final uri = Uri.parse(url);
    final response = await http.put(
      uri,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      showSuccessMessage('Updated');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TodoListPage(userId: widget.userId),
        ),
      );
    } else {
      showErrorMessage('Updation Failed');
      if (kDebugMode) {
        print(response.body);
      }
    }
  }

  Future<void> submitData() async {
    //get the data from form
    final title = titleController.text;
    final description = descriptionController.text;
    final body = {
      "taskName": title,
      "description": description,
      "userId": widget.userId,
    };
    //submit data to server
    final uri = Uri.parse('http://localhost:5000/tasks');
    final response = await http.post(
      uri,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
    //Map cannot be passed directly hence jsonEncoder converts map array into string

    //show success or fail message
    if (response.statusCode == 201) {
      titleController.text = '';
      descriptionController.text = '';
      showSuccessMessage('Creation Success');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TodoListPage(userId: widget.userId),
        ),
      );
    } else {
      showErrorMessage('Creation Failed');
      if (kDebugMode) {
        print(response.body);
      }
    }
  }

  void showSuccessMessage(String message) {
    final snackBar = SnackBar(
      content: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
      backgroundColor: Colors.green[300],
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showErrorMessage(String message) {
    final snackBar = SnackBar(
      content: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
      backgroundColor: Colors.red[400],
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
