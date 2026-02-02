var align = "";
var type = "";


function openExcel(gridIDArray , save) {
	try	{
		//excel activeX생성
		var objExcel = new ActiveXObject("excel.Application");
		//워크시트 생성
		var objWorkbook = objExcel.Workbooks.add();
		var gridIDList = gridIDArray.split(",");

		var chart = false;
		var i = 0;
		for ( i = 0 ; i < gridIDList.length ; i++ ){
			// 그리드ID추출
			var me = trim(gridIDList[i]);
		
			// 그리드 정보 추출
			getHeader(me);
			
			// 그리드의 속성 중 chart 포함 여부 체크
			try	{
				if(document.all(me).attribute("chart") == "true") chart = true;
			}
			catch(e)	{}
			// 엑셀 시트 생성
			objWorkbook.Sheets.Add();
			// 엑셀 시트 이름 지정
			objWorkbook.ActiveSheet.Name = document.all(me).attribute("id");
			// 엑셀 시트 활성화
			objWorkbook.Sheets(document.all(me).attribute("id")).Activate();

			var Sheet = objWorkbook.ActiveSheet;
			var nCnt = document.all(me).rows - document.all(me).fixedRows + 1;

			//col별 정렬 추출
			var col_algin = align.split(",");
			//col별 type 추출
			var col_type = type.split(",");

			for (var j=0   ;j < document.all(me).cols ; j++)		{
				// col의 width에 따라 excel cell의 열너비 지정
				Sheet.columns(j+1).columnWidth = document.all(me).colwidth(j) / 9.5;
				if (col_algin[j] == "center")			col_align_key = -4108;
				else	if (col_algin[j] == "right")	col_align_key = -4152;
				else									col_align_key = -4131;
				
				var rang = Sheet.Range( Sheet.cells( 1,  j+1 ),  Sheet.cells( document.all(me).rows,  j+1));
				rang.HorizontalAlignment = col_align_key;
				rang.VerticalAlignment = -4108;
			}

			for (var irow=document.all(me).FixedRows - 1; irow < nCnt ; irow++)	{
				for (var j=0 ; j < document.all(me).Cols; j++)	{
					// 그리드의 데이터를 excel cell에 write
					Sheet.cells(irow + 1  ,j+1) = document.all(me).textMatrix(irow ,j);
				}
			}

			//그리드의 caption에 해당하는 부분 색 칠하기
			var rang = Sheet.Range( Sheet.cells( 1,  1 ),  Sheet.cells( 1,  document.all(me).cols));
			rang.Interior.Color = window.rgb(217,217,217);

			// excel cell에 속성 부여
			rang = Sheet.Range( Sheet.cells( 1,  1 ),  Sheet.cells( document.all(me).rows,  document.all(me).cols));
			// cell 너비보다 데이터가 길면 여러줄로 표시
			rang.WrapText = true;
			// cell font 지정
			rang.font.name = "굴림";
			// cell font size 지정
			rang.font.size = 9;
			// cell서식 지정(텍스트)
			rang.numberFormat = "@";
			// cell 테두리 지정
			rang.borders.lineStyle = 1;
			// cell 테두리 두께 지정
			rang.borders.Weight = 2;

			// Draw Chart
			if (chart){
				// chart object 생성
				var ch = Sheet.ChartObjects.Add(rang.Left, rang.Top + rang.Height + 20 , 600, 300);
				// chart 종류 지정
				ch.Chart.ChartType = 51;

				ch.Chart.SetSourceData(rang, 2);
			}
			// excel cell의 행높이를 데이터의 길이에 따라 조절
			Sheet.rows.autoFit;
		}

		// 불필요한 sheet 삭제
		while (objWorkbook.Worksheets.Count > i)	{
			objWorksheet = objWorkbook.Worksheets.Item(objWorkbook.Worksheets.Count);
			objWorksheet.Delete;
		}

		if (save == "" || save == null) save = "false";

		// 파일 저장여부 확인
		if ( save == "true" ){
			// 파일 저장후 open
			var File_PATH = window.fileDialog("save","","true","","xls","Excel Files(*.xls)|*.xls");
			objWorkbook.SaveAs(File_PATH);
			window.exec(File_PATH);
		}
		else	{
			// 파일 저장은 안하고 open
			objExcel.Visible = true;
		}
	}
	catch (e){
		Sheet.Close(0);
		objExcel.Quit();
		alert("[makeExcelChart ERROR]::" + e.toString());
	}
}

function saveExcel( gridIDArray ) {

	var File_PATH = window.fileDialog("save","","true","","xls","Excel Files(*.xls)|*.xls");

	if (File_PATH != "")	{

		var tfexcel2 = body.createChild("xforms:object" , "id:tfexcel;clsid:{fe8d1001-6a9d-424d-ae2a-301493bb12da}");
		body.refresh();

		tfexcel.launchnewinstance(0);

		//실행된 excel application에서 새로운 workbook을 생성
		tfexcel.createworkbook();

		var gridIDList = gridIDArray.split(",");

		for ( var i = 0 ; i < gridIDList.length ; i++ ){

			var me = trim(gridIDList[i]);

			tfexcel.addsheet(i+1 , document.all(me).attribute("id") );

			//설정한 영역에 format을 설정
			tfexcel.setformat(1,1,document.all(me).rows,document.all(me).cols, "@");
			tfexcel.setbordercolor(1,1,document.all(me).rows,document.all(me).cols, "#000000");
			tfexcel.cellbgcolor(1,1,1,document.all(me).cols) = "#d9d9d9";
			tfexcel.font(1,1,document.all(me).rows,document.all(me).cols) =  document.all(me).attribute("font-falmily");
			tfexcel.fontsize(1,1,document.all(me).rows,document.all(me).cols) = 9;

			var col_algin = align.split(",");
			var col_type = type.split(",");

			for( col = 1 ; col <= document.all(me).cols ; col++)	{
				tfexcel.colwidth(col) = document.all(me).colwidth(col-1) / 9.5;

				tfexcel.halign(1,col,document.all(me).rows,col) = col_algin[col-1];
			}

			for (var gridRow=1 ; gridRow <= document.all(me).rows; gridRow++) {
				tfexcel.rowheight(gridRow) = document.all(me).rowheight(gridRow-1);
				for (var gridCol=1 ; gridCol <= document.all(me).cols; gridCol++) {
					if ( document.all(me).cellFormat( gridRow-1 , gridCol-1 ) != "" || col_type[gridCol-1] == "combo")	{
						tfexcel.cellvalue(gridRow,gridCol) = document.all(me).labelMatrix( gridRow-1 , gridCol-1 );
					}
					else	{
						tfexcel.cellvalue(gridRow,gridCol) = document.all(me).valueMatrix( gridRow-1 , gridCol-1 );
					}
				}
			}

		}
		for ( var i = 1 ; i <= 3 ; i++ ){
			tfexcel.deletesheet(gridIDList.length + 1);
		}

		//workbook을 저장.
		tfexcel.save(File_PATH);

		//excel application을 종료. excel application 생성 후 반드시 close해야함.
		tfexcel.close();

		//excel 실행
		window.exec("excel.exe",File_PATH);
	}
	else	{
		alertBox("EXCEL 저장이 취소 되었습니다");
	}

}

function getHeader(me){

	try{
		var t_align = "";
		var t_type = "";

		for( var i = 1 ; i < document.all(me).children.length; i++){
			if( document.all(me).children(i).elementName == "xforms:col" ){
				t_align += document.all(me).children(i).attribute("text-align") + ",";
				t_type += document.all(me).children(i).attribute("type") + ",";
			}
		}

		align 	= t_align.substring(0,t_align.length - 1);
		type 	= t_type.substring(0,t_type.length - 1);

	}catch(e){

		alertBox("[getHeader]::"+e);
	}
}

function trim(trimData){
  return trimData.replace(/(^\s*)|(\s*$)/gi, "");
}