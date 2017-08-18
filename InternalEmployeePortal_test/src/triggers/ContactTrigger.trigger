trigger ContactTrigger on Contact (after insert, after update) {
  if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
      SharingHelper.shareRecords('Contact', 'Employee_User__c', Trigger.old, Trigger.new);
  }
}