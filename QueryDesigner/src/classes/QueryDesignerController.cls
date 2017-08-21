public class QueryDesignerController {

    public static String getSObjects() {
        List<ObjectType> sObjectsList = new List<ObjectType>();

        for (Schema.SObjectType sObjectType : Schema.getGlobalDescribe().values()) {
            String objType = String.valueOf(sObjectType);
            List<String> fields = getFields(objType);

            sObjectsList.add(
                new ObjectType(objType, fields)
            );
        }

        return JSON.serialize(sObjectsList);
    }    

    private static List<String> getFields(String sObjectType) {
        Map <String, Schema.SObjectField> fieldMap = 
            Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap();

        List<String> fieldsList = new List<String>();

        for (Schema.SObjectField field : fieldMap.values()) {
            String fieldName = String.valueOf(field);
            //Schema.DisplayType fieldType = fieldMap.get(fieldName).getDescribe().getType();
            
            fieldsList.add(
                fieldName
                //new FieldType(fieldName, String.valueOf(fieldType))
            );
        }

        return fieldsList;
    }

    @RemoteAction
    public static List<sObject> executeQuery(String query) {
        List<sObject> resultList = Database.query(query);

        return resultList;
    }

    public class ObjectType {
        String objectTypeName { get; set; }
        List<String> fields { get; set; }
        
        public ObjectType(String objectTypeName, List<String> fields) {
            this.objectTypeName = objectTypeName;
            this.fields = fields;
        }
    }

    //public class FieldType {
    //    String fieldName { get; set; }
    //    String fieldType { get; set; }
        
    //    public FieldType(String fieldName, String fieldType) {
    //        this.fieldName = fieldName;
    //        this.fieldType = fieldType;
    //    }
    //}

}