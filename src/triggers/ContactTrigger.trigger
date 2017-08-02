trigger ContactTrigger on Contact (after insert, after update) {
  if (Trigger.isAfter && Trigger.isInsert || Trigger.isAfter && Trigger.isUpdate) {
      ContactTriggerHandler handler = new ContactTriggerHandler();
      handler.contactShare(Trigger.new);
  }
}