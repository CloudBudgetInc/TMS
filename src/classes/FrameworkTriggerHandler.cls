public class FrameworkTriggerHandler extends TriggerHandler{
	protected override void bulkBefore() {
        system.debug('bulk before');
    }
    protected override void beforeInsert() {
        system.debug('before insert');
    }
    protected override void beforeUpdate(){
        system.debug('before update');
    }
    protected override void beforeDelete(){
        system.debug('before delete');
    }
    protected override void afterInsert(){
        system.debug('after insert');
    }
    protected override void afterUpdate(){
        system.debug('after update');
    }
    protected override void afterDelete(){
        system.debug('after delete');
    }
    protected override void afterUndelete(){
        system.debug('after undelete');
    }
    protected override void finalActions(){
        system.debug('final actions');
    }
}