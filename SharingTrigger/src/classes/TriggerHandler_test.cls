@isTest
private class TriggerHandler_test {
  
  public static List<User> usersList;
  public static List<Contact> contact;

  static void init() {
    Account account = new Account(Name='Test Account');
    insert account;

    Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'Force.com - App Subscription User'];

    usersList = new List<User>();
    User newUser;
    
    newUser = new User(FirstName = 'Test', LastName = 'User1', Alias = 'tuser1', Email = 'user1@email.com', Username = 'user1@testvrp.com', CommunityNickname = 'testuser1',
      TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', ProfileId = profile.Id);
    insert newUser;
    usersList.add(newUser);

    newUser = new User(FirstName = 'Test', LastName = 'User2', Alias = 'tuser2', Email = 'user2@email.com', Username = 'user2@testvrp.com', CommunityNickname = 'testuser2', ManagerId = newUser.Id,
      TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', ProfileId = profile.Id);
    insert newUser;
    usersList.add(newUser);

    newUser = new User(FirstName = 'Test', LastName = 'User3', Alias = 'tuser3', Email = 'user3@email.com', Username = 'user3@testvrp.com', CommunityNickname = 'testuser3', ManagerId = newUser.Id,
      TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', ProfileId = profile.Id);
    insert newUser;
    usersList.add(newUser);

    contact = new List<Contact>();
    contact.add(new Contact(FirstName = 'Test Contact', LastName = 'FromEmloyee3', AccountId = account.Id, Employee_User__c = usersList.get(2).Id));
    contact.add(new Contact(FirstName = 'Test Contact', LastName = 'FromEmloyee2', AccountId = account.Id, Employee_User__c = usersList.get(1).Id));
    contact.add(new Contact(FirstName = 'Test Contact', LastName = 'FromEmloyee1', AccountId = account.Id, Employee_User__c = usersList.get(0).Id));
  }

  static testMethod void testInsertShare() {
    init();
    Test.startTest();

    insert contact;
    ContactTriggerHandler.insertShare(contact);

    List<ContactShare> contactsShare = [SELECT Id, UserOrGroupId, ContactAccessLevel, RowCause FROM ContactShare WHERE ContactId = :contact.get(0).Id AND UserOrGroupId = :usersList.get(2).Id];
    System.assert(contactsShare.size() > 0);
    for (ContactShare cs : contactsShare) {
      System.assertEquals(cs.ContactAccessLevel, 'Edit');
      System.assertEquals(cs.RowCause, 'Manual');
    }

    String searchStr = 'ManagerUp_' + contact.get(0).Employee_User__c;
    List<Group> groups = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :searchStr];
    
    contactsShare = [SELECT Id, UserOrGroupId, ContactAccessLevel, RowCause FROM ContactShare WHERE ContactId = :contact.get(0).Id AND UserOrGroupId = :groups.get(0).Id];
    System.assert(contactsShare.size() > 0);
    for (ContactShare cs : contactsShare) {
      System.assertEquals(cs.ContactAccessLevel, 'Edit');
      System.assertEquals(cs.RowCause, 'Manual');
    }

    Test.stopTest();
  }

  static testMethod void testUpdateShare() {
    init();
    Test.startTest();
    
    insert contact;
    List<Contact> oldContact = contact;
    contact.get(0).Employee_User__c = usersList.get(1).Id;
    contact.get(1).FirstName = 'FirstName';
    contact.get(2).Employee_User__c = usersList.get(2).Id;
    update contact;
    ContactTriggerHandler.updateShare(oldContact, contact);

    List<ContactShare> contactsShare = [SELECT Id, UserOrGroupId, ContactAccessLevel, RowCause FROM ContactShare WHERE ContactId = :contact.get(0).Id AND UserOrGroupId = :usersList.get(1).Id];
    System.assert(contactsShare.size() > 0);
    for (ContactShare cs : contactsShare) {
      System.assertEquals(cs.ContactAccessLevel, 'Edit');
      System.assertEquals(cs.RowCause, 'Manual');
    }

    String searchStr = 'ManagerUp_' + contact.get(0).Employee_User__c;
    List<Group> groups = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :searchStr];
    
    contactsShare = [SELECT Id, UserOrGroupId, ContactAccessLevel, RowCause FROM ContactShare WHERE ContactId = :contact.get(0).Id AND UserOrGroupId = :groups.get(0).Id];
    System.assert(contactsShare.size() > 0);
    for (ContactShare cs : contactsShare) {
      System.assertEquals(cs.ContactAccessLevel, 'Edit');
      System.assertEquals(cs.RowCause, 'Manual');
    }

    Test.stopTest();
  }
	
}