import { LightningElement, api, wire } from 'lwc';
import getMember360 from '@salesforce/apex/Member360Controller.getMember360';

const COVERAGE_COLUMNS = [
    { label: 'Plan', fieldName: 'Plan_Name__c' },
    { label: 'Type', fieldName: 'Coverage_Type__c' },
    { label: 'Member #', fieldName: 'Member_Number__c' },
    { label: 'Effective', fieldName: 'Effective_Date__c', type: 'date-local' },
    { label: 'Terminates', fieldName: 'Termination_Date__c', type: 'date-local' }
];

const ENCOUNTER_COLUMNS = [
    { label: 'Date', fieldName: 'Encounter_Date__c', type: 'date' },
    { label: 'Type', fieldName: 'Encounter_Type__c' },
    { label: 'Provider', fieldName: 'Provider_Name__c' },
    { label: 'Diagnosis', fieldName: 'Primary_Diagnosis__c' }
];

export default class Member360 extends LightningElement {
    @api recordId;
    member;
    error;
    coverageColumns = COVERAGE_COLUMNS;
    encounterColumns = ENCOUNTER_COLUMNS;

    @wire(getMember360, { memberId: '$recordId' })
    wired({ data, error }) {
        if (data) {
            this.member = data;
            this.error = undefined;
        } else if (error) {
            this.member = undefined;
            this.error = error.body ? error.body.message : 'Unable to load member';
        }
    }

    get subtitle() {
        const parts = [];
        if (this.member.age !== undefined && this.member.age !== null) {
            parts.push(`Age ${this.member.age}`);
        }
        if (this.member.location) {
            parts.push(this.member.location);
        }
        if (this.member.activeCoverage) {
            parts.push(this.member.activeCoverage.Plan_Name__c);
        }
        return parts.join(' · ');
    }

    get coverageBadgeClass() {
        return this.member.coverageStatus === 'Active' ? 'slds-theme_success' : 'slds-theme_error';
    }

    get hasAlerts() {
        return this.member.alerts && this.member.alerts.length > 0;
    }

    get carePlanCount() {
        return (this.member.activeCarePlans || []).length;
    }

    get careTeamCount() {
        return (this.member.careTeam || []).length;
    }
}
