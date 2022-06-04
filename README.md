# Jingle  Pectus

## Код JS, используемый на Word Press

### Данная часть кода интегрируется в виде шорткода на сайте WordPress, отвечающая за создание кнопки по загрузке аудио-файла на сайт

```javascript
	<style type="text/css">
		.file-upload2 input[type="file"]{ 
			display: none;/* скрываем input file */ 
		} 
		.file-form-wrap2{
			width:100%; 
			margin-left:27%;
		} 
		.file-upload2 {
			position: relative; 
			overflow: hidden; 
			width: 51%;
			height:50px;
			line-height:50px;
			background: #3a3a3a; 
			border-radius: 10px; 
			color: #fff; 
			text-align: center; 
		} 
		.file-upload2:hover { 
			background: #545454; 
		} 
		/* Растягиваем label на всю область блока .file-upload */ 
		.file-upload2 label { 
			display: block; 
			position: absolute; 
			top: 0; 
			left: 0; 
			width: 100%; 
			height: 100%; 
			cursor: pointer; 
		} 
		/* стиль текста на кнопке*/ 
		.file-upload2 span { 
 
			font-size:16px;
			font-style:normal;
			font-weight:400px;
			line-height:0.4
		}
		.preview-img{ 
			max-width:100px; 
			max-height:100px; 
			margin:5px; 
		}
	</style>	
		<div class="file-form-wrap2">
		<div class="file-upload2">
			<label>
				<input id="uploaded-file2" type="file" name="file2" onchange="getFileParam2();" accept="audio/*">
				<span>Выберите аудио-файл</span><br />
			</label>
		</div>
		<div id="preview2">&nbsp;</div>
		<div id="file-name2">&nbsp;</div>
		<div id="file-size2">&nbsp;</div>
	</div>
 
<script src="https://www.gstatic.com/firebasejs/3.7.4/firebase.js"></script>
<script>
  var config = {
  apiKey: "AIzaSyDrBDLpgA6Kbm7ufySvTTPzjsnL0RBR__Y",
  authDomain: "chatting-2d1b9.firebaseapp.com",
  projectId: "chatting-2d1b9",
  storageBucket: "chatting-2d1b9.appspot.com",
  messagingSenderId: "886808601783",
  appId: "1:886808601783:web:6dbaf65d53e8ae96385932",
  measurementId: "G-J1DG38ZG6K"
  };
  firebase.initializeApp(config);
//-------------------------------------
  var fileButton2 = document.getElementById('uploaded-file2');
 
  fileButton2.addEventListener('change', function(e){
  var file2 = e.target.files[0];
  if ((Math.round(file2.size * 100 / (1024 * 1024)) / 100) > 3) {
	  document.getElementById('file-name2').innerHTML =  "<span style = 'color:red;'>Размер вашего файла превышает 3МБ</span>";
	  document.getElementById('file-size2').innerHTML = '';
	  exit();
  }
  var storageRef2 = firebase.storage().ref('sounds/'+file2.name);
  var task2 = storageRef2.put(file2);
});
</script>
<script type="text/javascript">
	function getFileParam2() { 			
		try { 				
			var file2 = document.getElementById('uploaded-file2').files[0]; 				
 
			if (file2) { 					
				var fileSize = 0;					
 
				if (file2.size > 1024 * 1024) {
					fileSize = (Math.round(file2.size * 100 / (1024 * 1024)) / 100).toString() + 'MB';
				}else {
					fileSize = (Math.round(file2.size * 100 / 1024) / 100).toString() + 'KB';
				}
		        if ((Math.round(file2.size * 100 / (1024 * 1024)) / 100) > 3) {
	                document.getElementById('file-name2').innerHTML = "<span style = 'color:red;'>Размер вашего файла превышает 3МБ</span>";
	                exit();
  }			
				document.getElementById('file-name2').innerHTML = 'Вы выбрали файл: ' + file2.name;
				document.getElementById('file-size2').innerHTML = 'Размер файла: ' + fileSize;
 
				if (/\.(jpe?g|bmp|gif|png)$/i.test(file2.name)) {		
					var elPreview = document.getElementById('preview2');
					elPreview.innerHTML = '';
					var newImg = document.createElement('img');
					newImg.className = "preview-img";
 
					if (typeof file2.getAsDataURL=='function') {
						if (file2.getAsDataURL().substr(0,11)=='data:image/') {
							newImg.onload=function() {
								document.getElementById('file-name2').innerHTML+=' ('+newImg.naturalWidth+'x'+newImg.naturalHeight+' px)';
							}
							newImg.setAttribute('src',file2.getAsDataURL());
							elPreview.appendChild(newImg);								
						}
					}else {
						var reader = new FileReader();
						reader.onloadend = function(evt) {
							if (evt.target.readyState == FileReader.DONE) {
								newImg.onload=function() {
									document.getElementById('file-name2').innerHTML+=' ('+newImg.naturalWidth+'x'+newImg.naturalHeight+' px)';
								}
 
								newImg.setAttribute('src', evt.target.result);
								elPreview.appendChild(newImg);
							}
						};
 
						var blob;		
						if (file2.slice) {
							blob = file2.slice(0, file2.size);
						}else if (file2.webkitSlice) {
								blob = file2.webkitSlice(0, file2.size);
							}else if (file2.mozSlice) {
								blob = file2.mozSlice(0, file2.size);
							}
						reader.readAsDataURL(blob);
					}
				}
			}
		}catch(e) {
			var file2 = document.getElementById('uploaded-file2').value;
			file2 = file2.replace(/\\/g, "/").split('/').pop();
			document.getElementById('file-name2').innerHTML = 'Вы выбрали: ' + file2;
		}
	}
	</script>
```
### Данная часть кода интегрируется в виде шорткода на сайте WordPress, отвечающая за создание кнопки по загрузке изображения на сайт, а также вывода сообщений о размере файла и передаче файла в Storage Firebase
```javascript
<style type="text/css">
		.file-upload input[type="file"]{ 
			display: none;/* скрываем input file */ 
		} 
		.file-form-wrap{
			width:100%;
			margin-left:27%;
 
		} 
		.file-upload { 
			position: relative; 
			overflow: hidden; 
			width: 51%;
			height:50px;
			line-height:50px;
			background: #3a3a3a; 
			border-radius: 10px; 
			color: #fff; 
			text-align: center; 
		} 
		.file-upload:hover { 
			background: #545454; 
		} 
		/* Растягиваем label на всю область блока .file-upload */ 
		.file-upload label { 
			display: block; 
			position: absolute; 
			top: 0; 
			left: 0; 
			width: 100%; 
			height: 100%; 
			cursor: pointer; 
		} 
		/* стиль текста на кнопке*/ 
		.file-upload span { 
 
			font-size:16px;
			font-style:normal;
			font-weight:400px;
			line-height:0.4
		}
		.preview-img{ 
			max-width:100px; 
			max-height:100px; 
			margin:5px; 
		}
 
	</style>	
 
	<div class="file-form-wrap">
		<div class="file-upload">
			<label>
				<input id="uploaded-file1" type="file" name="file" onchange="getFileParam();" accept="image/*">
				<span>Выберите изображение</span><br />
			</label>
		</div>
		<div id="preview1">&nbsp;</div>
		<div id="file-name1" class="1">&nbsp;</div>
		<div id="file-size1" class="2">&nbsp;</div>
	</div>
<script src="https://www.gstatic.com/firebasejs/3.7.4/firebase.js"></script>
<script src="https://www.gstatic.com/firebasejs/6.0.2/firebase-firestore.js"></script>
 
<script>
  var config = {
  apiKey: "AIzaSyDrBDLpgA6Kbm7ufySvTTPzjsnL0RBR__Y",
  authDomain: "chatting-2d1b9.firebaseapp.com",
  projectId: "chatting-2d1b9",
  storageBucket: "chatting-2d1b9.appspot.com",
  messagingSenderId: "886808601783",
  appId: "1:886808601783:web:6dbaf65d53e8ae96385932",
  measurementId: "G-J1DG38ZG6K"
  };
  firebase.initializeApp(config);
//-------------------------------------
  var fileButton = document.getElementById('uploaded-file1');
 
  fileButton.addEventListener('change', function(e){
  var file = e.target.files[0];
  if ((Math.round(file.size * 100 / 1024) / 100) > 200) {
	  document.getElementById('file-name1').innerHTML = "<span style = 'color:red;'>Размер вашего файла превышает 200 КБ</span>";
	  document.getElementById('preview1').innerHTML = '';
	  document.getElementById('file-size1').innerHTML = '';
	  exit();
  }
  var storageRef = firebase.storage().ref('stickers/'+file.name);/*getDownloadUrl*/
  var task = storageRef.put(file);/*firestoreDatabase*/
 
 
});
</script>
<script type="text/javascript">
	function getFileParam() { 			
		try { 				
			var file = document.getElementById('uploaded-file1').files[0]; 				
 
			if (file) { 					
				var fileSize = 0;					
 
				if (file.size > 1024 * 1024) {
					fileSize = (Math.round(file.size * 100 / (1024 * 1024)) / 100).toString() + 'MB';
				}else {
					fileSize = (Math.round(file.size * 100 / 1024) / 100).toString() + 'KB';
				}
				  if ((Math.round(file.size * 100 / 1024) / 100) > 200) {
	                document.getElementById('file-name1').innerHTML =  "<span style = 'color:red;'>Размер вашего файла превышает 200 КБ</span>";
					document.getElementById('preview1').innerHTML = '';
 
	                exit();
  }
				document.getElementById('file-name1').innerHTML = 'Вы выбрали файл: ' + file.name;
				document.getElementById('file-size1').innerHTML = 'Размер файла: ' + fileSize;
 
				if (/\.(jpe?g|bmp|gif|png)$/i.test(file.name)) {		
					var elPreview = document.getElementById('preview1');
					elPreview.innerHTML = '';
					var newImg = document.createElement('img');
					newImg.className = "preview-img";
 
					if (typeof file.getAsDataURL=='function') {
						if (file.getAsDataURL().substr(0,11)=='data:image/') {
							newImg.onload=function() {
								document.getElementById('file-name1').innerHTML+=' ('+newImg.naturalWidth+'x'+newImg.naturalHeight+' px)';
							}
							newImg.setAttribute('src',file.getAsDataURL());
							elPreview.appendChild(newImg);								
						}
					}else {
						var reader = new FileReader();
						reader.onloadend = function(evt) {
							if (evt.target.readyState == FileReader.DONE) {
								newImg.onload=function() {
									document.getElementById('file-name1').innerHTML+=' ('+newImg.naturalWidth+'x'+newImg.naturalHeight+' px)';
								}
 
								newImg.setAttribute('src', evt.target.result);
								elPreview.appendChild(newImg);
 
						}
						};
 
						var blob;		
						if (file.slice) {
							blob = file.slice(0, file.size);
						}else if (file.webkitSlice) {
								blob = file.webkitSlice(0, file.size);
							}else if (file.mozSlice) {
								blob = file.mozSlice(0, file.size);
							}
						reader.readAsDataURL(blob);
					}
				}
			}
		}catch(e) {
			var file = document.getElementById('uploaded-file1').value;
			file = file.replace(/\\/g, "/").split('/').pop();
			document.getElementById('file-name1').innerHTML = 'Вы выбрали: ' + file;
		}
	}
	</script>
```
### Данная часть кода интегрируется в виде шорткода на сайте WordPress, отвечающая за создание формы по выбору/созданию тега на вебсайте и использующая Select2
```javascript
<script src="https://code.jquery.com/jquery-3.3.1.min.js"></script>
<link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet"/>
<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>
<div class = "form">
<select class="form-control" style="width:65%" id = "form_control">
    <option value="0" disabled selected>Выберите/введите не более 1-го тега</option>
    <option value="1" custom-attribute="a">hi</option>
	<option value="2" custom-attribute="b">хахаха</option>	
	<option value="3" custom-attribute="c">ну погоди!</option>	
	<option value="4" custom-attribute="d">тра-ля-ля</option>	
	<option value="5" custom-attribute="e">красотища то какая!</option>
	<option value="6" custom-attribute="f">это мое болото</option>	
	<option value="7" custom-attribute="g">давай до свидания</option>	
	<option value="8" custom-attribute="k">бдыщ</option>
	<option value="9" custom-attribute="l">смешно</option>
	<option value="10" custom-attribute="m">очень смешно</option>	
	<option value="11" custom-attribute="n">стыдобища</option>	
	<option value="12" custom-attribute="o">стыд и срам</option>	
	<option value="13" custom-attribute="p">кек</option>	
	<option value="14" custom-attribute="r">лол</option>	
</select>
</div>
 
<script>
$(".form-control").select2({
/*	maximumSelectionLength: 3,*/
	tags: true,
	placeholder: "Выберите/введите не более 1-го тега"
});
$('#form-control').select2().on('select2:open', function(e){
    $('.select2-search__field').attr('placeholder', 'your placeholder');
});
 
$('form-control').select2({
  createTag: function (params) {
    var term = $.trim(params.term);
 
    if (term === '') {
      return null;
    }
 
    return {
      id: term,
      text: term,
      newTag: true // add additional parameters
    }
  }
});
 
 
</script>
 
 
<style>
.err{
	margin-left: 28%;
	}
.form{
	margin-left: 28%;
	}
.bt {
    background-color: #3a3a3a; 
    border: none;
    color: white;
    text-align: center;
    text-decoration: none;
    display: inline-block;
    font-size: 15px;
	line-height:50px;
	border-radius: 10px;
	height:50px;
	width: 50%;
	margin-left: 26%;
}
.bt:active {
  background-color: #ffffff;
  transform: translateY(4px);
}
.bt:hover {
    background-color: #424242; /* Green */
    color: #2FC824;
	border: black;
 
}
 
.tr{
display: block;
background-color: #3a3a3a;
color: #fff;
padding: 7px;
text-align: center;
width:60%;
height:25%;
font-size:12px;
margin-top:0;
margin-bottom:0;
opacity:0.3;
	}
/* Input field */
.select2-selection__rendered {
color: black;
}
 
/* Around the search field */
.select2-search {
color: black;
}
 
/* Search field */
.select2-search input {color: black;}
 
/* Each result */
.select2-results {color: black;}
 
/* Higlighted (hover) result */
.select2-results__option--highlighted {  }
 
/* Selected option */
</style>
```
### Данная часть кода интегрируется в виде шорткода на сайте WordPress, отвечающая за создание кнопки по загрузке аудио-стикера на сайте, а также отвечающая за получение ссылок загруженных файлов из Storage для добавления стикера в FireStore Database
```javascript
<p><button type="button" class = "bt">Создать аудио-стикер</button></p>
<div id="err" class="err">&nbsp;</div>
 
<script>
	 $("button").click(function(){
        var tg = [];
        $.each($(".form-control option:selected"), function(){            
            tg.push($(this).text());
        });
	   //$("div.tr").text("Вы выбрали теги: " + tg.join(", "));
    var file2 = document.getElementById('uploaded-file2').files[0];
	if (typeof(file2) == 'undefined' || ((Math.round(file2.size * 100 / (1024 * 1024)) / 100) > 3)){
	  document.getElementById('err').innerHTML = "<span style = 'color: red ;'>Ошибка!Загрузите звук!</span>";
	  exit();
	}
	var storageRef2 = firebase.storage().ref('sounds/'+file2.name);
	storageRef2.getDownloadURL().then((url2)=>{       
	   var file = document.getElementById('uploaded-file1').files[0];
 
	   if (typeof(file) == 'undefined'|| ((Math.round(file.size * 100 / 1024) / 100) > 200)){
	     document.getElementById('err').innerHTML ="<span style = 'color: red ;'>Ошибка!Загрузите изображение!</span>";
	     exit();
	}
       var storageRef = firebase.storage().ref('stickers/'+file.name);
       storageRef.getDownloadURL().then((url)=>{
	   if ((tg) == "Выберите/введите не более 1-го тега"){
	     document.getElementById('err').innerHTML ="<span style = 'color: red ;'>Ошибка!Выберите тег!</span>";
	     exit();
	}		   
		  var database = firebase.firestore();
          var dataObject = {
            img: url,
            name: tg[0],
            sound: url2,
            tag:tg[0]
          };
database.collection('stickers').add(dataObject);
	     document.getElementById('err').innerHTML ="<span style = 'color: #2FC824 ;'>Ваш аудио-стикер загружен.</span>";
 
});
});
 
 });
</script>
```
