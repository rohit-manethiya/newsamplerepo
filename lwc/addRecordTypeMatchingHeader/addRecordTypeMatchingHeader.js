import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/copadoCorePubsub';

// Import custom labels
import recordMatchingFormula from '@salesforce/label/c.Record_Matching_Formula';

export default class AddRecordTypeMatchingHeader extends LightningElement {
    @api recordMatchingName;
    @wire(CurrentPageReference) pageRef;

    // Expose the labels to use in the template.
    label = {
        recordMatchingFormula
    };

    saveFormula(event) {
        fireEvent(this.pageRef, 'saveFormulaClickedEvent', event.target.value);
    }
}