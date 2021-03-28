public with sharing class VehicleTriggerHelper {
    private static List<Vehicle__c> targetVehicles;
    private static List<Maintenance__c> targetMaintenances;

    public static void checkStatusAfterInsert(List<Vehicle__c> insertedVehicles) {
        Map<String, String> emailForDriver = new Map<String, String>();
        for (Vehicle__c vehicle : insertedVehicles) {
            if (!isStatusAvailable(vehicle.Status__c, '')) {
                emailForDriver.put(vehicle.Driver__r.Email, (String.format(Constants.STATUS_MESSAGE,
                        new List<Object>{
                                vehicle.Plate_Number__c, vehicle.Vehicle_Model__c
                        })));
            }
        }
        sendEmailToDrivers(emailForDriver);
    }

    public static void checkStatusAfterUpdate(Map<Id, Vehicle__c> vehicleNewMap, Map<Id, Vehicle__c> vehicleOldMap) {
        Map<String, String> emailForDriver = new Map<String, String>();
        for (Id vehicleId : vehicleNewMap.keySet()) {
            Vehicle__c newStatusValue = vehicleNewMap.get(vehicleId);
            Vehicle__c oldStatusValue = vehicleOldMap.get(vehicleId);
            if (!isStatusAvailable(newStatusValue.Status__c, oldStatusValue.Status__c)) {
                emailForDriver.put(newStatusValue.Driver__r.Email,
                        (String.format(
                                Constants.STATUS_MESSAGE,
                                new List<Object>{
                                        newStatusValue.Plate_Number__c, newStatusValue.Vehicle_Model__c
                                }
                        )));
            }
        }
        sendEmailToDrivers(emailForDriver);
    }

    public static void initDataForMaintenanceProcess(Map<Id, Vehicle__c> vehicleNewMap, Map<Id, Vehicle__c> vehiclesOldMap) {
        targetVehicles = new List<Vehicle__c>();
        targetMaintenances = new List<Maintenance__c>();
        for (Id vehicleId : vehicleNewMap.keySet()) {
            Vehicle__c newValue = vehicleNewMap.get(vehicleId);
            Vehicle__c oldValue = vehiclesOldMap.get(vehicleId);
            nextMaintenanceDateValidation(newValue);
            if (oldValue.Next_Maintenance_Date__c != newValue.Next_Maintenance_Date__c) {
                targetVehicles.add(newValue);
            }
        }
    }

    public static void checkNextMaintenanceDateInsert(List<Vehicle__c> insertedVehicles) {
        for (Vehicle__c vehicle : insertedVehicles) {
            nextMaintenanceDateValidation(vehicle);
        }
    }

    public static void updateMaintenanceProcess() {
        Map<String, String> emailForDriver = new Map<String, String>();
        List<Vehicle__c> targetVehicles = [
                SELECT
                        Id, Driver__r.Email,
                        Next_Maintenance_Date__c,
                        Last_Maintenance_Date__c,
                        Plate_Number__c
                FROM Vehicle__c
                WHERE Id IN :targetVehicles
        ];
        for (Vehicle__c vehicle : targetVehicles) {
            Maintenance__c tempMaintenance = new Maintenance__c();
            tempMaintenance.Scheduled_maintenance_date__c = vehicle.Next_Maintenance_Date__c + 14;
            tempMaintenance.Vehicle__c = vehicle.Id;
            emailForDriver.put(vehicle.Driver__r.Email, ('New maintenance is scheduled for vehicle '
                    + vehicle.Plate_Number__c + ' from ' + tempMaintenance.Scheduled_maintenance_date__c
                    + ' to ' + vehicle.Next_Maintenance_Date__c));

            targetMaintenances.add(tempMaintenance);
        }
        sendEmailToDrivers(emailForDriver);
        insert targetMaintenances;
    }

    public static void assignMaintenance() {
        for (Vehicle__c vehicle : targetVehicles) {
            for (Maintenance__c maintenance : targetMaintenances) {
                if (maintenance.Vehicle__c == vehicle.Id) {
                    vehicle.Last_Maintenance_Date__c = (Date) maintenance.Id;
                }
            }
        }
    }

    public static Boolean isStatusAvailable(String newStatus, String oldStatus) {
        if (oldStatus == '' && newStatus != Constants.STATUS_AVAILABLE) {
            return false;
        }
        if (oldStatus == Constants.STATUS_AVAILABLE && newStatus != Constants.STATUS_AVAILABLE) {
            return false;
        }
        return true;
    }

    public static void nextMaintenanceDateValidation(Vehicle__c vehicleItem) {
        if (vehicleItem.Next_Maintenance_Date__c < vehicleItem.Last_Maintenance_Date__c) {
            vehicleItem.Next_Maintenance_Date__c.addError(Constants.VALIDATE_DATE_ERROR);
        }
    }

    public static void sendEmailToDrivers(Map<String, String> emailsMap) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (String email : emailsMap.keySet()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>();
            toAddresses.add(email);
            mail.setToAddresses(toAddresses);
            mail.setSubject('Status changed');
            mail.setPlainTextBody(emailsMap.get(email));
            emails.add(mail);
        }
        Messaging.sendEmail(emails);
    }
}