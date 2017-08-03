trigger ContactTrigger on Contact (after insert, after update) {
  if (Trigger.isAfter) {
    if (Trigger.isInsert) {
      ContactTriggerHandler.insertShare(Trigger.new);
    } else if (Trigger.isUpdate) {
      ContactTriggerHandler.updateShare(Trigger.old, Trigger.new);
    }
  }
}