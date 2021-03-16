import { LightningElement, api } from 'lwc';

export default class AddRecordTypeMatchingFilter extends LightningElement {
    @api order;
    @api mainFilterOptions;
    @api secondFilterOptions;
    @api selectedFilterValue;
    @api showSecondFilterPicklist;
    @api selectedSecondFilterValue;

    handleMainPicklistChange(event) {
        event.preventDefault();
        let changedValue = {
            order: this.order,
            selectedFilterValue: event.detail.value
        };

        // dispatch event for parent
        const changePicklistValueEvent = new CustomEvent('populatefilteroptions', {
            detail: changedValue
        });
        this.dispatchEvent(changePicklistValueEvent);
    }

    handleSecondPicklistChange(event) {
        event.preventDefault();
        let changedValue = {
            order: this.order,
            selectedFilterValue: event.detail.value
        };

        // dispatch event for parent
        const changeSecondPicklistValueEvent = new CustomEvent('populatesecondfilteroptions', {
            detail: changedValue
        });
        this.dispatchEvent(changeSecondPicklistValueEvent);
    }

    handleRemovePicklistValues(event) {
        event.preventDefault();
        this.selectedFilterValue = '';
        this.selectedSecondFilterValue = '';
        let changedValue = {
            order: this.order,
            selectedFilterValue: '',
            showSecondFilterPicklist: false
        };

        // dispatch event for parent
        const removePicklistValueEvent = new CustomEvent('removefilteroptions', {
            detail: changedValue
        });
        this.dispatchEvent(removePicklistValueEvent);
    }
}