import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/database/app_database.dart';

void main() {
  test(
    'migration removes active unlinked goals and manual balance column',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'goal_migration_',
      );
      final file = File('${directory.path}/test.sqlite');
      final old = AppDatabase.forTesting(NativeDatabase(file));
      late int accountId;
      try {
        accountId = await old.insertAccount(
          AccountsCompanion.insert(name: 'Savings'),
        );
        await old
            .into(old.goals)
            .insert(
              GoalsCompanion.insert(
                profileId: 1,
                name: 'Linked goal',
                target: 10000,
                dueDate: DateTime(2099, 10, 15),
                anchorDate: DateTime(2099, 10, 15),
                accountId: Value(accountId),
              ),
            );
        await old
            .into(old.goals)
            .insert(
              GoalsCompanion.insert(
                profileId: 1,
                name: 'Unlinked active goal',
                target: 10000,
                dueDate: DateTime(2099, 10, 15),
                anchorDate: DateTime(2099, 10, 15),
              ),
            );
        await old
            .into(old.goals)
            .insert(
              GoalsCompanion.insert(
                profileId: 1,
                name: 'Paused goal',
                target: 10000,
                dueDate: DateTime(2099, 10, 15),
                anchorDate: DateTime(2099, 10, 15),
                status: const Value('paused'),
              ),
            );
        await old.customStatement(
          'ALTER TABLE goals ADD COLUMN manual_saved INTEGER NOT NULL DEFAULT 0',
        );
        await old.customStatement('PRAGMA user_version = 14');
      } finally {
        await old.close();
      }

      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final goals = await upgraded.select(upgraded.goals).get();
        expect(goals.map((goal) => goal.name), ['Linked goal', 'Paused goal']);
        expect(goals.first.accountId, accountId);
        expect(goals.last.status, 'paused');
        final columns = await upgraded
            .customSelect('PRAGMA table_info(goals)')
            .get();
        expect(
          columns.map((column) => column.read<String>('name')),
          isNot(contains('manual_saved')),
        );
      } finally {
        await upgraded.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
