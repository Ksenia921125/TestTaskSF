public class ContactTriggerHandler {
  
  public ContactTriggerHandler() {}

  public void contactShare(List<Contact> contact_list) {
    // Map<Contact.Id, Group.DeveloperName>
    Map<String, String> sharing_groups = new Map<String, String>();
    for (Contact c : contact_list) {
      sharing_groups.put(c.Id, 'ManagerUp_' + c.Employee_User__c);
    }

    // Map<Group.DeveloperName, Group.Id>
    Map<String, String> group_map = new Map<String, String>();
    for (Group g : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :sharing_groups.values()]) {
      group_map.put(g.DeveloperName, g.Id);
    }

    List<ContactShare> contactShrs = new List<ContactShare>();
    ContactShare contactShr;

    for (String contact_id : sharing_groups.keySet()) {
      contactShr = new ContactShare();
      contactShr.ContactAccessLevel = 'Edit';
      contactShr.ContactId = contact_id;
      contactShr.RowCause = Schema.ContactShare.RowCause.Manual;
      contactShr.UserOrGroupId = group_map.get(sharing_groups.get(contact_id));
      contactShrs.add(contactShr);
    } 

    Database.SaveResult[] lsr = Database.insert(contactShrs, false);

    Integer i = 0; 

    for(Database.SaveResult sr : lsr) {
      if(!sr.isSuccess()) {
        Database.Error err = sr.getErrors()[0];
        if(!(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION && err.getMessage().contains('AccessLevel'))) {
          trigger.newMap.get(contactShrs[i].ContactId).addError('Unable to grant sharing access due to following exception: ' + err.getMessage());
        }
      }
      i++;
    }
  }
}