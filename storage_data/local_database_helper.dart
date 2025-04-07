import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

/// A utility class to manage a local SQLite database in Flutter apps.
/// 
/// This helper provides methods to create, read, update, and delete records,
/// as well as execute custom SQL queries and manage database migrations.
class LocalDatabaseHelper {
  /// Database instance
  Database? _database;
  
  /// Database name
  final String databaseName;
  
  /// Database version
  final int version;
  
  /// Tables to create
  final List<DatabaseTable> tables;
  
  /// Migrations to run
  final List<DatabaseMigration> migrations;
  
  /// Whether to log database operations
  final bool enableLogging;
  
  /// Singleton instance
  static LocalDatabaseHelper? _instance;
  
  /// Get the singleton instance
  static LocalDatabaseHelper get instance {
    if (_instance == null) {
      throw Exception('LocalDatabaseHelper not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the database helper
  static Future<LocalDatabaseHelper> initialize({
    required String databaseName,
    required int version,
    required List<DatabaseTable> tables,
    List<DatabaseMigration> migrations = const [],
    bool enableLogging = false,
  }) async {
    if (_instance != null) return _instance!;
    
    _instance = LocalDatabaseHelper._internal(
      databaseName: databaseName,
      version: version,
      tables: tables,
      migrations: migrations,
      enableLogging: enableLogging,
    );
    
    await _instance!._initialize();
    
    return _instance!;
  }
  
  /// Private constructor
  LocalDatabaseHelper._internal({
    required this.databaseName,
    required this.version,
    required this.tables,
    required this.migrations,
    required this.enableLogging,
  });
  
  /// Initialize the database
  Future<void> _initialize() async {
    _database = await _openDatabase();
  }
  
  /// Open the database
  Future<Database> _openDatabase() async {
    // Get the database path
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, databaseName);
    
    if (enableLogging) {
      debugPrint('Opening database at $path');
    }
    
    // Open the database
    return await openDatabase(
      path,
      version: version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
    );
  }
  
  /// Create the database tables
  Future<void> _onCreate(Database db, int version) async {
    if (enableLogging) {
      debugPrint('Creating database version $version');
    }
    
    // Create tables
    for (final table in tables) {
      await db.execute(table.createTableQuery);
      
      if (enableLogging) {
        debugPrint('Created table ${table.tableName}');
      }
    }
  }
  
  /// Upgrade the database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (enableLogging) {
      debugPrint('Upgrading database from $oldVersion to $newVersion');
    }
    
    // Run migrations
    for (final migration in migrations) {
      if (migration.fromVersion >= oldVersion && migration.toVersion <= newVersion) {
        await migration.migrate(db);
        
        if (enableLogging) {
          debugPrint('Ran migration from ${migration.fromVersion} to ${migration.toVersion}');
        }
      }
    }
  }
  
  /// Downgrade the database
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    if (enableLogging) {
      debugPrint('Downgrading database from $oldVersion to $newVersion');
    }
    
    // Run migrations
    for (final migration in migrations) {
      if (migration.fromVersion <= oldVersion && migration.toVersion >= newVersion) {
        await migration.rollback(db);
        
        if (enableLogging) {
          debugPrint('Rolled back migration from ${migration.fromVersion} to ${migration.toVersion}');
        }
      }
    }
  }
  
  /// Get the database instance
  Future<Database> get database async {
    if (_database == null) {
      _database = await _openDatabase();
    }
    return _database!;
  }
  
  /// Close the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
  
  /// Insert a record into a table
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    
    if (enableLogging) {
      debugPrint('Inserting into $table: $values');
    }
    
    return await db.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Insert multiple records into a table
  Future<List<int>> insertAll(String table, List<Map<String, dynamic>> valuesList) async {
    final db = await database;
    final batch = db.batch();
    
    if (enableLogging) {
      debugPrint('Inserting ${valuesList.length} records into $table');
    }
    
    for (final values in valuesList) {
      batch.insert(
        table,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    final results = await batch.commit();
    return results.cast<int>();
  }
  
  /// Update a record in a table
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    
    if (enableLogging) {
      debugPrint('Updating $table: $values, where: $where, whereArgs: $whereArgs');
    }
    
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }
  
  /// Delete a record from a table
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    
    if (enableLogging) {
      debugPrint('Deleting from $table, where: $where, whereArgs: $whereArgs');
    }
    
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }
  
  /// Delete all records from a table
  Future<int> deleteAll(String table) async {
    final db = await database;
    
    if (enableLogging) {
      debugPrint('Deleting all records from $table');
    }
    
    return await db.delete(table);
  }
  
  /// Query a table
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool distinct = false,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    
    if (enableLogging) {
      debugPrint('Querying $table, where: $where, whereArgs: $whereArgs');
    }
    
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }
  
  /// Get a record by ID
  Future<Map<String, dynamic>?> getById(String table, int id) async {
    final db = await database;
    
    if (enableLogging) {
      debugPrint('Getting record from $table with ID $id');
    }
    
    final results = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }
  
  /// Get all records from a table
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    
    if (enableLogging) {
      debugPrint('Getting all records from $table');
    }
    
    return await db.query(table);
  }
  
  /// Count records in a table
  Future<int> count(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    
    if (enableLogging) {
      debugPrint('Counting records in $table, where: $where, whereArgs: $whereArgs');
    }
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $table ${where != null ? 'WHERE $where' : ''}',
      whereArgs,
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// Execute a raw SQL query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    
    if (enableLogging) {
      debugPrint('Executing raw query: $sql, arguments: $arguments');
    }
    
    return await db.rawQuery(sql, arguments);
  }
  
  /// Execute a raw SQL statement
  Future<int> rawExecute(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    
    if (enableLogging) {
      debugPrint('Executing raw statement: $sql, arguments: $arguments');
    }
    
    return await db.rawUpdate(sql, arguments);
  }
  
  /// Execute a batch of operations
  Future<List<dynamic>> batch(
    Future<void> Function(Batch batch) operations,
  ) async {
    final db = await database;
    final batch = db.batch();
    
    await operations(batch);
    
    if (enableLogging) {
      debugPrint('Executing batch operations');
    }
    
    return await batch.commit();
  }
  
  /// Check if a table exists
  Future<bool> tableExists(String tableName) async {
    final db = await database;
    
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    
    return result.isNotEmpty;
  }
  
  /// Get the table schema
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async {
    final db = await database;
    
    return await db.rawQuery('PRAGMA table_info($tableName)');
  }
  
  /// Get all table names
  Future<List<String>> getTableNames() async {
    final db = await database;
    
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    
    return result.map((row) => row['name'] as String).toList();
  }
  
  /// Begin a transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    
    if (enableLogging) {
      debugPrint('Beginning transaction');
    }
    
    final result = await db.transaction(action);
    
    if (enableLogging) {
      debugPrint('Transaction completed');
    }
    
    return result;
  }
}

/// A class to represent a database table
class DatabaseTable {
  /// Table name
  final String tableName;
  
  /// SQL query to create the table
  final String createTableQuery;
  
  /// Create a new database table
  DatabaseTable({
    required this.tableName,
    required this.createTableQuery,
  });
  
  /// Create a table from a schema
  factory DatabaseTable.fromSchema({
    required String tableName,
    required List<DatabaseColumn> columns,
  }) {
    final columnDefinitions = columns.map((column) => column.definition).join(', ');
    final createTableQuery = 'CREATE TABLE $tableName ($columnDefinitions)';
    
    return DatabaseTable(
      tableName: tableName,
      createTableQuery: createTableQuery,
    );
  }
}

/// A class to represent a database column
class DatabaseColumn {
  /// Column name
  final String name;
  
  /// Column type
  final String type;
  
  /// Whether the column is a primary key
  final bool primaryKey;
  
  /// Whether the column is auto-incrementing
  final bool autoIncrement;
  
  /// Whether the column is nullable
  final bool nullable;
  
  /// Default value for the column
  final dynamic defaultValue;
  
  /// Whether the column is unique
  final bool unique;
  
  /// Create a new database column
  DatabaseColumn({
    required this.name,
    required this.type,
    this.primaryKey = false,
    this.autoIncrement = false,
    this.nullable = true,
    this.defaultValue,
    this.unique = false,
  });
  
  /// Get the column definition
  String get definition {
    final parts = <String>[];
    
    parts.add(name);
    parts.add(type);
    
    if (primaryKey) {
      parts.add('PRIMARY KEY');
    }
    
    if (autoIncrement) {
      parts.add('AUTOINCREMENT');
    }
    
    if (!nullable) {
      parts.add('NOT NULL');
    }
    
    if (defaultValue != null) {
      if (defaultValue is String) {
        parts.add("DEFAULT '${defaultValue.toString()}'");
      } else {
        parts.add('DEFAULT ${defaultValue.toString()}');
      }
    }
    
    if (unique) {
      parts.add('UNIQUE');
    }
    
    return parts.join(' ');
  }
  
  /// Create an ID column
  static DatabaseColumn id() {
    return DatabaseColumn(
      name: 'id',
      type: 'INTEGER',
      primaryKey: true,
      autoIncrement: true,
      nullable: false,
    );
  }
  
  /// Create a text column
  static DatabaseColumn text(
    String name, {
    bool nullable = true,
    String? defaultValue,
    bool unique = false,
  }) {
    return DatabaseColumn(
      name: name,
      type: 'TEXT',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    );
  }
  
  /// Create an integer column
  static DatabaseColumn integer(
    String name, {
    bool nullable = true,
    int? defaultValue,
    bool unique = false,
  }) {
    return DatabaseColumn(
      name: name,
      type: 'INTEGER',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    );
  }
  
  /// Create a real column
  static DatabaseColumn real(
    String name, {
    bool nullable = true,
    double? defaultValue,
    bool unique = false,
  }) {
    return DatabaseColumn(
      name: name,
      type: 'REAL',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    );
  }
  
  /// Create a boolean column
  static DatabaseColumn boolean(
    String name, {
    bool nullable = true,
    bool? defaultValue,
    bool unique = false,
  }) {
    return DatabaseColumn(
      name: name,
      type: 'INTEGER',
      nullable: nullable,
      defaultValue: defaultValue != null ? (defaultValue ? 1 : 0) : null,
      unique: unique,
    );
  }
  
  /// Create a timestamp column
  static DatabaseColumn timestamp(
    String name, {
    bool nullable = true,
    bool defaultNow = false,
    bool unique = false,
  }) {
    return DatabaseColumn(
      name: name,
      type: 'INTEGER',
      nullable: nullable,
      defaultValue: defaultNow ? 'CURRENT_TIMESTAMP' : null,
      unique: unique,
    );
  }
}

/// A class to represent a database migration
class DatabaseMigration {
  /// Migration from version
  final int fromVersion;
  
  /// Migration to version
  final int toVersion;
  
  /// Function to migrate the database
  final Future<void> Function(Database db) migrate;
  
  /// Function to rollback the migration
  final Future<void> Function(Database db) rollback;
  
  /// Create a new database migration
  DatabaseMigration({
    required this.fromVersion,
    required this.toVersion,
    required this.migrate,
    required this.rollback,
  });
}

/// A base class for database models
abstract class DatabaseModel {
  /// Convert the model to a map
  Map<String, dynamic> toMap();
  
  /// Get the table name
  String get tableName;
  
  /// Save the model to the database
  Future<int> save() async {
    final map = toMap();
    
    if (map.containsKey('id') && map['id'] != null) {
      return await LocalDatabaseHelper.instance.update(
        tableName,
        map,
        where: 'id = ?',
        whereArgs: [map['id']],
      );
    } else {
      return await LocalDatabaseHelper.instance.insert(tableName, map);
    }
  }
  
  /// Delete the model from the database
  Future<int> delete() async {
    final map = toMap();
    
    if (map.containsKey('id') && map['id'] != null) {
      return await LocalDatabaseHelper.instance.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [map['id']],
      );
    }
    
    return 0;
  }
}

/// Example usage:
///
/// ```dart
/// // Define a model class
/// class User extends DatabaseModel {
///   final int? id;
///   final String name;
///   final String email;
///   final int age;
///   final bool isActive;
///   
///   User({
///     this.id,
///     required this.name,
///     required this.email,
///     required this.age,
///     this.isActive = true,
///   });
///   
///   @override
///   String get tableName => 'users';
///   
///   @override
///   Map<String, dynamic> toMap() {
///     return {
///       if (id != null) 'id': id,
///       'name': name,
///       'email': email,
///       'age': age,
///       'is_active': isActive ? 1 : 0,
///     };
///   }
///   
///   factory User.fromMap(Map<String, dynamic> map) {
///     return User(
///       id: map['id'] as int?,
///       name: map['name'] as String,
///       email: map['email'] as String,
///       age: map['age'] as int,
///       isActive: map['is_active'] == 1,
///     );
///   }
/// }
///
/// // Initialize the database
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Define tables
///   final userTable = DatabaseTable.fromSchema(
///     tableName: 'users',
///     columns: [
///       DatabaseColumn.id(),
///       DatabaseColumn.text('name', nullable: false),
///       DatabaseColumn.text('email', nullable: false, unique: true),
///       DatabaseColumn.integer('age', nullable: false),
///       DatabaseColumn.boolean('is_active', defaultValue: true),
///       DatabaseColumn.timestamp('created_at', defaultNow: true),
///     ],
///   );
///   
///   // Define migrations
///   final addPhoneNumberMigration = DatabaseMigration(
///     fromVersion: 1,
///     toVersion: 2,
///     migrate: (db) async {
///       await db.execute('ALTER TABLE users ADD COLUMN phone_number TEXT');
///     },
///     rollback: (db) async {
///       // SQLite doesn't support dropping columns, so we need to recreate the table
///       await db.execute('CREATE TABLE users_temp AS SELECT id, name, email, age, is_active, created_at FROM users');
///       await db.execute('DROP TABLE users');
///       await db.execute('ALTER TABLE users_temp RENAME TO users');
///     },
///   );
///   
///   // Initialize the database helper
///   await LocalDatabaseHelper.initialize(
///     databaseName: 'my_app.db',
///     version: 2,
///     tables: [userTable],
///     migrations: [addPhoneNumberMigration],
///     enableLogging: true,
///   );
///   
///   runApp(MyApp());
/// }
///
/// // Use the database
/// class UserRepository {
///   // Create a user
///   Future<User> createUser(User user) async {
///     final id = await user.save();
///     return User(
///       id: id,
///       name: user.name,
///       email: user.email,
///       age: user.age,
///       isActive: user.isActive,
///     );
///   }
///   
///   // Get a user by ID
///   Future<User?> getUserById(int id) async {
///     final map = await LocalDatabaseHelper.instance.getById('users', id);
///     if (map == null) return null;
///     return User.fromMap(map);
///   }
///   
///   // Get all users
///   Future<List<User>> getAllUsers() async {
///     final maps = await LocalDatabaseHelper.instance.getAll('users');
///     return maps.map((map) => User.fromMap(map)).toList();
///   }
///   
///   // Update a user
///   Future<int> updateUser(User user) async {
///     return await user.save();
///   }
///   
///   // Delete a user
///   Future<int> deleteUser(User user) async {
///     return await user.delete();
///   }
///   
///   // Get active users
///   Future<List<User>> getActiveUsers() async {
///     final maps = await LocalDatabaseHelper.instance.query(
///       'users',
///       where: 'is_active = ?',
///       whereArgs: [1],
///     );
///     return maps.map((map) => User.fromMap(map)).toList();
///   }
///   
///   // Get users by age range
///   Future<List<User>> getUsersByAgeRange(int minAge, int maxAge) async {
///     final maps = await LocalDatabaseHelper.instance.query(
///       'users',
///       where: 'age >= ? AND age <= ?',
///       whereArgs: [minAge, maxAge],
///       orderBy: 'age ASC',
///     );
///     return maps.map((map) => User.fromMap(map)).toList();
///   }
///   
///   // Count users
///   Future<int> countUsers() async {
///     return await LocalDatabaseHelper.instance.count('users');
///   }
///   
///   // Execute a custom query
///   Future<List<User>> searchUsers(String query) async {
///     final maps = await LocalDatabaseHelper.instance.rawQuery(
///       'SELECT * FROM users WHERE name LIKE ? OR email LIKE ?',
///       ['%$query%', '%$query%'],
///     );
///     return maps.map((map) => User.fromMap(map)).toList();
///   }
/// }
/// ```
