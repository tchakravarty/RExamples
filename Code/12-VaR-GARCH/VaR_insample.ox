#include <oxstd.h>
#include <oxdraw.h>
#import <packages/Garch/garch>

main()
{
	decl garchobj;
	garchobj = new Garch();

//*** DATA ***//
	garchobj.Load("./data/nasdaq.xls"); // -> B4094 
	garchobj.Select(Y_VAR, {"Nasdaq",0,0} );
	garchobj.SetSelSample(1, 1, 2000, 1); 		
	garchobj.Info();          
                                 
//*** SPECIFICATIONS ***//
	garchobj.CSTS(1,1); 			// cst in Mean (1 or 0), cst in Variance (1 or 0)	
	garchobj.DISTRI(3);				// 0 for Gauss, 1 for Student, 2 for GED, 3 for Skewed-Student
	garchobj.ARMA_ORDERS(2,0); 		// AR order (p), MA order (q).
	garchobj.ARFIMA(0);				// 1 if Arfima wanted, 0 otherwise
	garchobj.GARCH_ORDERS(1,1);		// p order, q order
	garchobj.MODEL(4);				//	0:RISKMETRICS  1:GARCH		2:EGARCH	3:GJR	4:APARCH	5:IGARCH
									//  6:FIGARCH(BBM)	7:FIGARCH(Chung)	8:FIEGARCH(BBM only)
									//  9:FIAPARCH(BBM)	10: FIAPARCH(Chung)	11: HYGARCH(BBM)
	
//*** OUTPUT ***//	
	garchobj.MLE(0);				// 0 : Second Derivates, 1 : OPG, 2 : QMLE
	garchobj.ITER(0);				// Interval of iterations between printed intermediary results (if no intermediary results wanted, enter '0')

//*** PARAMETERS ***//	
	garchobj.BOUNDS(0);				// 1 if bounded parameters wanted, 0 otherwise
	garchobj.FIXPARAM(0,<0;0;0;1;1;1>);
			 						// Arg.1 : 1 to fix some parameters to their starting values, 0 otherwize
									// Arg.2 : 1 to fix (see garchobj.DoEstimation(<>)) and 0 to estimate the corresponding parameter
	garchobj.Initialization(<>);
	garchobj.DoEstimation(<>);
	garchobj.Output();

	decl quan=<0.95,0.975,0.99,0.995,0.9975>; // Quantiles investigated

	decl Y=garchobj.GetGroup(Y_VAR);
	decl T=garchobj.GetcT();
	decl m_cA,m_cV,i,j;
	decl qu_pos,qu_neg,m_vSigma2,dfunc,m_vPar,cond_mean;
	decl m_Dist=garchobj.GetValue("m_cDist");

	println("Infos");
	println("Number of observations: ", T);
	println("Investigated quantiles: ",quan);
	println("In-sample VaR");

/* ************************************************************************************************ */
	decl emp_quan_in_pos=new matrix[T][columns(quan)];
	decl emp_quan_in_neg=new matrix[T][columns(quan)];
	m_vSigma2=garchobj.GetValue("m_vSigma2");
	cond_mean=Y-garchobj.GetValue("m_vE");
	if (m_Dist==0)
	{
		qu_pos=quann(quan)';
		qu_neg=quann(1-quan)';	
	}
	if (m_Dist==1)
	{
		m_cV=garchobj.GetValue("m_cV");
		qu_pos=sqrt((m_cV-2)/m_cV)*quant(quan,m_cV)';
		qu_neg=sqrt((m_cV-2)/m_cV)*quant(1-quan,m_cV)';
	}
	if (m_Dist==3)
	{
		m_cV=garchobj.GetValue("m_cV");
		m_cA=garchobj.GetValue("m_cA");
		qu_pos=qu_neg=<>;
		for (i = 0; i < columns(quan) ; ++i)    
		{
			qu_pos|=garchobj.INVCDFTA(quan[i],m_cA,m_cV);
			qu_neg|=garchobj.INVCDFTA(1-quan[i],m_cA,m_cV);
		}
	}

	emp_quan_in_pos=(cond_mean + sqrt(m_vSigma2).*qu_pos'); //
	emp_quan_in_neg=(cond_mean + sqrt(m_vSigma2).*qu_neg'); //

	println("In-sample Value-at-Risk");
	garchobj.VaR_DynQuant(Y, emp_quan_in_pos, emp_quan_in_neg, quan, 5, 0,0);
	garchobj.VaR_Test(Y, emp_quan_in_pos, emp_quan_in_neg, quan);

	delete garchobj;
}