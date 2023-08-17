@isTest
public class TEST_ReceiptingMapping_Custom {

    public static testMethod void testMappingClass() {
        ReceiptingMapping_Custom mappingClass = new ReceiptingMapping_Custom();
        System.assertEquals(mappingClass.getObjects().size(), 3);
        System.assertEquals(mappingClass.getSingleReceiptableObjects().size(), 1);
        System.assertEquals(mappingClass.getRecurringReceiptableObjects().size(), 1);
        System.assertEquals(mappingClass.getEventReceiptableObjects().size(), 2);
        System.assert(!mappingClass.getAccompanyingLetterPlaceholders().isEmpty());
        System.assert(!mappingClass.getAccompanyingLetterInstallmentPlaceholders().isEmpty());
    }
}