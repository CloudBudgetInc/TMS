public class batchCreateByDate{
	public String batchId {get;set;}
	public Integer oppAssigned {get;set;}

	public batchCreateByDate(String batchId, Integer opp){
		this.batchId = batchId;
		this.oppAssigned = opp;
	}
}