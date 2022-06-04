## приложение Jingle 

Код, используемый на Word Press

```javascript
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
