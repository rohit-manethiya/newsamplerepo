import { LightningElement } from 'lwc';

import Dynamic_Parameter_Helper from '@salesforce/label/c.Dynamic_Parameter_Helper';
import Parameter_Context from '@salesforce/label/c.Parameter_Context';
import Parameter_Field from '@salesforce/label/c.Parameter_Field';
import Variable_Value from '@salesforce/label/c.VarVal';
import Dynamic_Variable_Helper_Helptext from '@salesforce/label/c.Dynamic_Variable_Helper_Helptext';
import COPY_TO_CLIPBOARD from '@salesforce/label/c.COPY_TO_CLIPBOARD';

const _parameterContexts = {
    'Copado Org': 'CopadoOrg',
    'Source Environment': 'Source',
    'Destination Environment': 'Destination',
    Deployment: 'Deployment',
    Promotion: 'Promotion',
    'Resume URL': 'ResumeURL'
};

const _parameterFieldsByContext = {
    CopadoOrg: ['Org Id', 'Credential Id', 'Api Key'],
    Source: ['Org Id', 'Credential Id'],
    Destination: ['Org Id', 'Credential Id'],
    Deployment: ['Id', 'Job Id'],
    Promotion: ['Id'],
    ResumeURL: []
};

export default class DeploymentStepsDynamicVariableHelper extends LightningElement {
    label = {
        Dynamic_Parameter_Helper,
        Parameter_Context,
        Parameter_Field,
        Variable_Value,
        Dynamic_Variable_Helper_Helptext,
        COPY_TO_CLIPBOARD
    };

    parameterContext = '';
    get parameterContexts() {
        const contexts = Object.keys(_parameterContexts).map((context) => {
            return { label: context, value: _parameterContexts[context] };
        });
        return contexts;
    }

    parameterField = '';
    get parameterFields() {
        let fields = [];
        if (this.parameterContext) {
            fields = _parameterFieldsByContext[this.parameterContext];
            fields = fields.map((field) => {
                return { label: field, value: field.replace(' ', '') };
            });
        }
        return fields;
    }

    get variable() {
        if (this.parameterContext) {
            return `{!${this.parameterContext}${this.parameterField ? '.' + this.parameterField : ''}}`;
        }
        return '';
    }

    handleChange(event) {
        this.parameterField = '';
        this[event.target.name] = event.target.value;
    }

    handleCopyVariable() {
        const element = this.template.querySelector('textarea');
        element.select();
        document.execCommand('copy');
    }
}