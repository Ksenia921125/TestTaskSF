public class ContactTriggerHandler {
  
  public static void insertShare(List<Contact> contactList) {
    
    try {
      Database.query('SELECT Id FROM ContactShare LIMIT 1');      
    } catch(Exception e) {
      return;
    }

    // Map<Contact.Id, User.Id>
    Map<String, String> sharingUsers = new Map<String, String>();
    for (Contact c : contactList) {
      sharingUsers.put(c.Id, c.Employee_User__c);
    }

    // Map<Contact.Id, Group.Id>
    Map<String, String> sharingGroups = getSharingGroups(sharingUsers);

    List<ContactShare> contactShrs = getShares(sharingUsers, sharingGroups);

    Database.SaveResult[] lsr = Database.insert(contactShrs, false);
  }

  public static void updateShare(List<Contact> oldContacts, List<Contact> newContacts) {
    
    try {
      Database.query('SELECT Id FROM ContactShare LIMIT 1');      
    } catch(Exception e) {
      return;
    }

    // Map<Contact.Id, User.Id>
    Map<String, String> sharingUsers = new Map<String, String>();
    Map<String, String> forDelete = new Map<String, String>();

    for (Contact cOld : oldContacts) {
      for (Contact cNew : newContacts) {
        if (cOld.Employee_User__c != cNew.Employee_User__c) {
          sharingUsers.put(cNew.Id, cNew.Employee_User__c);
          forDelete.put(cOld.Id, cOld.Employee_User__c);
        }
      }
    }

    Map<String, String> sharingGroups = getSharingGroups(sharingUsers);

    List<ContactShare> deleteRecords = [SELECT Id FROM ContactShare WHERE UserOrGroupId = :forDelete.values()];
    Database.delete(deleteRecords, false);
    forDelete = getSharingGroups(forDelete);
    deleteRecords = [SELECT Id FROM ContactShare WHERE UserOrGroupId = :forDelete.values()];
    Database.delete(deleteRecords, false);

    List<ContactShare> contactShrs = getShares(sharingUsers, sharingGroups);

    Database.SaveResult[] lsr = Database.insert(contactShrs, false);
  }

  // return Map<Contact.Id, Group.Id>
  private static Map<String, String> getSharingGroups(Map<String, String> sharingUsers) {
    List<String> namesForGroup = new List<String>();
    for (String g : sharingUsers.values()) {
      namesForGroup.add('ManagerUp_' + g);
    }

    Map<String, String> groups = new Map<String, String>();
    for (Group g : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :namesForGroup]) {
      groups.put(g.DeveloperName, g.Id);
    }

    Map<String, String> sharingGroups = new Map<String, String>();
    for (String contactId : sharingUsers.keySet()) {
      sharingGroups.put(contactId, groups.get('ManagerUp_' + sharingUsers.get(contactId)));
    }

    return sharingGroups;
  }

  private static List<ContactShare> getShares(Map<String, String> users, Map<String, String> groups) {
    List<ContactShare> shares = new List<ContactShare>();
    ContactShare contactShrForGroup;
    ContactShare contactShrForUser;

    for (String contactId : users.keySet()) {
      contactShrForGroup = new ContactShare();
      contactShrForUser = new ContactShare();

      contactShrForGroup.ContactAccessLevel = 'Edit';
      contactShrForGroup.ContactId = contactId;
      contactShrForGroup.RowCause = Schema.ContactShare.RowCause.Manual;
      contactShrForGroup.UserOrGroupId = groups.get(contactId);

      contactShrForUser.ContactAccessLevel = 'Edit';
      contactShrForUser.ContactId = contactId;
      contactShrForUser.RowCause = Schema.ContactShare.RowCause.Manual;
      contactShrForUser.UserOrGroupId = users.get(contactId);

      shares.add(contactShrForGroup);
      shares.add(contactShrForUser);
    }
    return shares;
  }

}