using Base.Test
@test_throws Exception DynAssMgmt.loadTestData("dkflsj")
@test isa(DynAssMgmt.loadTestData("fx"), TimeSeries.TimeArray)
