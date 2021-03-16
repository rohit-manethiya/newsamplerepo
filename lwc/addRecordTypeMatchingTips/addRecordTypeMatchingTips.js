import { LightningElement } from 'lwc';

// Import custom labels
import recordMatchingTip1 from '@salesforce/label/c.ADD_Record_Matching_Tip_1';
import recordMatchingTip2 from '@salesforce/label/c.ADD_Record_Matching_Tip_2';
import recordMatchingTip3 from '@salesforce/label/c.ADD_Record_Matching_Tip_3';
import recordMatchingTip4 from '@salesforce/label/c.ADD_Record_Matching_Tip_4';
import formulaTips from '@salesforce/label/c.Copado_Pro_Formula_Tips';

export default class AddRecordTypeMatchingTips extends LightningElement {
    // Expose the labels to use in the template.
    label = {
        recordMatchingTip1,
        recordMatchingTip2,
        recordMatchingTip3,
        recordMatchingTip4,
        formulaTips
    };
}