<<<<<<< HEAD

import 'package:flutter/material.dart';
import 'models/user_infor.dart';
import 'database/database_helper.dart';
import 'models/journal_prompt.dart';
import 'models/journal_entry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyDatabaseApp());
}

class MyDatabaseApp extends StatelessWidget {
  const MyDatabaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Journal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const UserHomePage(),
    );
  }
}

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  // USER PROFILE STATE
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  String _gender = 'prefer_not_to_say';
  String _employmentStatus = 'student';
  List<UserInfo> _users = [];
  bool _isLoadingUsers = true;
  String? _userError;

  static const Map<String, String> _genders = {
    'male': 'Male',
    'female': 'Female',
    'non_binary': 'Non-binary',
    'prefer_not_to_say': 'Prefer not to say',
  };

  static const Map<String, String> _employmentStatuses = {
    'student': 'Student',
    'employed': 'Employed',
    'unemployed': 'Unemployed',
    'self_employed': 'Self-employed',
    'retired': 'Retired',
  };

  // JOURNAL STATE
  final _entryController = TextEditingController();
  List<JournalPrompt> _prompts = [];
  List<JournalEntry> _entries = [];

  bool _isLoadingJournal = true;
  String? _journalError;
  String? _selectedCategory;
  String? _selectedPromptText;
  int? _editingEntryId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadJournal();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ---------------- USER PROFILES ----------------

  Future<void> _loadUsers() async {
    try {
      final users = await DatabaseHelper.instance.getUsers();

      if (!mounted) return;

      setState(() {
        _users = users;
        _isLoadingUsers = false;
        _userError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingUsers = false;
        _userError = 'Could not load users: $error';
      });
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    final user = UserInfo(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _gender,
      employmentStatus: _employmentStatus,
    );

    try {
      final newId =
          await DatabaseHelper.instance.insertUser(user);

      await DatabaseHelper.instance.addLog(
        userId: newId,
        action: 'Created user profile',
      );

      _nameController.clear();
      _ageController.clear();

      setState(() {
        _gender = 'prefer_not_to_say';
        _employmentStatus = 'student';
      });

      await _loadUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User saved successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save user: $error')),
      );
    }
  }

  Future<void> _deleteUser(UserInfo user) async {
    if (user.id == null) return;

    try {
      await DatabaseHelper.instance.deleteUser(user.id!);

      await DatabaseHelper.instance.addLog(
        action: 'Deleted user ${user.id}',
      );

      await _loadUsers();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete user: $error')),
      );
    }
  }

  String _choiceLabel(
    Map<String, String> choices,
    String value,
  ) {
    return choices[value] ?? value;
  }

  // ---------------- JOURNAL ----------------

  Future<void> _loadJournal() async {
    try {
      final prompts = await DatabaseHelper.instance.getPrompts();
      final entries = await DatabaseHelper.instance.getEntries();

      if (!mounted) return;

      setState(() {
        _prompts = prompts;
        _entries = entries;
        _isLoadingJournal = false;
        _journalError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingJournal = false;
        _journalError = 'Could not load journal: $error';
      });
    }
  }

  List<String> get _categories {
    final categories = _prompts
        .map((prompt) => prompt.category)
        .toSet()
        .toList();

    categories.sort();
    return categories;
  }

  Future<void> _saveEntry() async {
    final content = _entryController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write something before saving.'),
        ),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.saveEntry(
        content: content,
        promptText: _selectedPromptText,
        id: _editingEntryId,
      );

      await _loadJournal();

      if (!mounted) return;

      setState(() {
        _entryController.clear();
        _selectedPromptText = null;
        _editingEntryId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingEntryId == null
                ? 'Entry saved!'
                : 'Entry updated!',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save entry: $error')),
      );
    }
  }

  void _editEntry(JournalEntry entry) {
    setState(() {
      _editingEntryId = entry.id;
      _entryController.text = entry.content;
      _selectedPromptText = entry.promptText;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingEntryId = null;
      _selectedPromptText = null;
      _entryController.clear();
    });
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    if (entry.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text(
          'This journal entry will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DatabaseHelper.instance.deleteEntry(entry.id!);

      if (_editingEntryId == entry.id) {
        _cancelEditing();
      }

      await _loadJournal();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete entry: $error')),
      );
    }
  }

  Future<void> _addPrompt() async {
    final promptController = TextEditingController();
    final categoryController = TextEditingController(text: 'General');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create a prompt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: promptController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'What made you happy today?',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'General, School, Personal...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (promptController.text.trim().isEmpty ||
                  categoryController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Add prompt'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final category = categoryController.text.trim();

        await DatabaseHelper.instance.addPrompt(
          promptText: promptController.text.trim(),
          category: category,
        );

        if (!mounted) return;

        setState(() {
          _selectedCategory = category;
        });

        await _loadJournal();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt added!')),
        );
      } catch (error) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add prompt: $error')),
        );
      }
    }

    promptController.dispose();
    categoryController.dispose();
  }

  // ---------------- SCREEN ----------------

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quick Journal'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.edit_note),
                text: 'Journal',
              ),
              Tab(
                icon: Icon(Icons.person_outline),
                text: 'Profiles',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildJournalTab(),
            _buildProfilesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalTab() {
    if (_isLoadingJournal) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_journalError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_journalError!),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoadingJournal = true;
                    _journalError = null;
                  });
                  _loadJournal();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final categories = _categories;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'A little time for yourself',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose a prompt or write whatever is on your mind.',
        ),
        const SizedBox(height: 20),

        // Prompt section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Writing prompts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              tooltip: 'Add a custom prompt',
              onPressed: _addPrompt,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),

        if (categories.isNotEmpty)
          DropdownButtonFormField<String?>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Filter by category',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All categories'),
              ),
              ...categories.map(
                (category) => DropdownMenuItem<String?>(
                  value: category,
                  child: Text(category),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),

        const SizedBox(height: 8),

        ..._prompts
            .where(
              (prompt) =>
                  _selectedCategory == null ||
                  prompt.category == _selectedCategory,
            )
            .map(
              (prompt) => Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(prompt.promptText),
                  subtitle: Text(prompt.category),
                  trailing: IconButton(
                    tooltip: 'Use this prompt',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      setState(() {
                        _selectedPromptText = prompt.promptText;
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _selectedPromptText = prompt.promptText;
                    });
                  },
                ),
              ),
            ),

        if (_prompts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No prompts yet. Tap + to create your first one.',
            ),
          ),

        const Divider(height: 32),

        // Writing section
        Text(
          _editingEntryId == null
              ? 'Write an entry'
              : 'Edit your entry',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        if (_selectedPromptText != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Your prompt'),
              subtitle: Text(_selectedPromptText!),
              trailing: IconButton(
                tooltip: 'Remove prompt',
                onPressed: () {
                  setState(() {
                    _selectedPromptText = null;
                  });
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ),

        const SizedBox(height: 8),

        TextField(
          controller: _entryController,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Start writing here...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saveEntry,
            icon: const Icon(Icons.save_outlined),
            label: Text(
              _editingEntryId == null ? 'Save entry' : 'Update entry',
            ),
          ),
        ),

        if (_editingEntryId != null)
          TextButton(
            onPressed: _cancelEditing,
            child: const Text('Cancel editing'),
          ),

        const Divider(height: 32),

        // Saved entries
        Text(
          'Your journal (${_entries.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 8),

        if (_entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Your journal is empty. Write your first entry above!',
            ),
          )
        else
          ..._entries.map(
            (entry) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.promptText != null &&
                        entry.promptText!.isNotEmpty) ...[
                      Text(
                        entry.promptText!,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(entry.content),
                    const SizedBox(height: 8),
                    Text(
                      'Updated: ${entry.updatedAt}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Edit entry',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editEntry(entry),
                        ),
                        IconButton(
                          tooltip: 'Delete entry',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteEntry(entry),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfilesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Add a user',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),

        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Please enter a name.'
                        : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final age = int.tryParse(value?.trim() ?? '');
                  return age == null || age < 0
                      ? 'Enter a valid age (0 or older).'
                      : null;
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: _genders.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _gender = value);
                  }
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _employmentStatus,
                decoration: const InputDecoration(
                  labelText: 'Employment status',
                  border: OutlineInputBorder(),
                ),
                items: _employmentStatuses.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _employmentStatus = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveUser,
                  child: const Text('Save user'),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 32),

        Text(
          'Saved users (${_users.length})',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),

        if (_isLoadingUsers)
          const Center(child: CircularProgressIndicator())
        else if (_userError != null)
          Text(
            _userError!,
            style: const TextStyle(color: Colors.red),
          )
        else if (_users.isEmpty)
          const Text('No users saved yet.')
        else
          ..._users.map(
            (user) => Card(
              child: ListTile(
                title: Text(user.name),
                subtitle: Text(
                  'Age: ${user.age}\n'
                  'Gender: ${_choiceLabel(_genders, user.gender)}\n'
                  'Employment: ${_choiceLabel(_employmentStatuses, user.employmentStatus)}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Delete user',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteUser(user),
                ),
              ),
            ),
          ),
      ],
    );
  }
=======
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO(backend): switch to the serious_python-backed dependencies once the
  // Python branch is merged (see AppDependencies.mock for details).
  runApp(JourneyApp(deps: AppDependencies.mock()));
>>>>>>> origin/main
}
