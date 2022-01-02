﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace PostGrad_Web_App
{
	public partial class MainMaster : System.Web.UI.MasterPage
	{
		protected void Page_Load(object sender, EventArgs e)
		{

		}
		protected void SignOut_Click(object sender, EventArgs e)
		{
			Session.Clear();
			Session.Abandon();
			FormsAuthentication.SignOut();
			Response.Redirect("~/Login.aspx");
		}
	}
}