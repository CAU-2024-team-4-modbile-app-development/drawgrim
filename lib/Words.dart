import 'package:flutter/material.dart';

class Words extends ChangeNotifier{
  final List<String> foodList = [
    '라면',
    '김밥',
    '떡볶이',
    '햄버거',
    '피자',
    '핫도그',
    '치킨',
    '초밥',
    '샌드위치',
    '아이스크림',
    '빵',
    '과자',
    '주스',
    '스파게티',
    '샐러드',
    '스테이크',
    '감자튀김',
    '수박',
    '사과',
    '바나나',
    '김치',
    '된장찌개',
    '비빔밥',
    '불고기',
    '갈비',
    '삼겹살',
    '잡채',
    '갈비탕',
    '감자전',
    '전복죽',
    '오징어볶음',
    '호떡',
    '순대',
    '해물파전',
    '닭갈비',
    '족발',
    '보쌈',
    '곰탕',
    '설렁탕',
    '칼국수',
    '타코',
    '파에야',
    '토르티야',
    '파스타',
    '라자냐',
    '치즈버거',
    '크로와상',
    '감바스',
    '케밥',
    '샤오롱바오',
    '스시',
    '카레',
    '팟타이',
    '초코퐁듀',
    '햄치즈오믈렛',
    '오코노미야끼',
    '양꼬치',
    '스콘',
    '핫초콜릿',
    '비프웰링턴',
    '마카롱',
    '와플',
    '도넛',
    '초콜릿',
    '푸딩',
    '젤리',
    '크레이프',
    '팥빙수',
    '에클레어',
    '카스테라',
    '쿠키',
    '케이크',
    '머핀',
    '티라미수',
    '츄러스',
    '파운드케이크',
    '수플레',
    '아이스크림콘',
    '호두파이',
    '모나카',
    '커피',
    '녹차',
    '라떼',
    '버블티',
    '생강차',
    '망고스무디',
    '칵테일',
    '레모네이드',
    '딸기우유',
    '맥주',
    '와인',
    '사과주스',
    '코코넛워터',
    '에스프레소',
    '밀크셰이크',
    '자몽에이드',
    '스무디볼',
    '카푸치노',
    '코코아',
    '에이드',
  ];
  final List<String> plantList = [
    "사시 나무", "오동 나무", "카카오 나무", "은행 나무", "자작 나무",
    "느티나무", "벚나무", "소나무", "전나무", "가문비나무",
    "잣나무", "삼나무", "배나무", "포플러", "구상나무",
    "참나무", "단풍나무", "떡갈나무", "버드나무", "대추나무",
    "무화과나무", "감나무", "매화나무", "사과나무", "살구나무",
    "아카시아", "라일락", "진달래", "개나리", "장미",
    "국화", "수선화", "해바라기", "튤립", "아이리스",
    "민들레", "카네이션", "접시꽃", "패랭이꽃", "나팔꽃",
    "칸나", "코스모스", "동백꽃", "들국화", "수련",
    "연꽃", "산호수", "마름", "갈대", "솜사탕나무",
    "맨드라미", "배추꽃", "파리지옥", "바오밥나무", "코르크나무",
    "목련", "메타세쿼이아", "유칼립투스", "밀싹", "보리",
    "강낭콩", "완두콩", "고구마", "감자", "옥수수",
    "벼", "밀", "호밀", "팥", "녹두",
    "밤나무", "호두나무", "잎새삼", "담쟁이덩굴", "선인장",
    "양치식물", "소철", "고사리", "풍란", "난초",
    "칡", "황금목련", "푸른대나무", "붉은대나무", "참깨",
    "콩나물", "깻잎", "민트", "로즈마리", "라벤더",
    "세이지", "타임", "바질", "레몬그라스", "히비스커스",
    "핑크뮬리", "자스민", "올리브나무", "포도나무", "유자나무"
  ];
  final List<String> animalList = [
    "개", "고양이", "나무늘보", "사자", "호랑이",
    "코끼리", "기린", "코알라", "판다", "늑대",
    "여우", "곰", "토끼", "다람쥐", "두더지",
    "고슴도치", "하마", "물소", "들소", "캥거루",
    "치타", "표범", "재규어", "야크", "라마",
    "고라니", "노루", "사슴", "멧돼지", "미어캣",
    "악어", "도마뱀", "카멜레온", "뱀", "거북이",
    "개구리", "두꺼비", "잉어", "송어", "상어",
    "고래", "돌고래", "바다표범", "바다사자", "해달",
    "펭귄", "알바트로스", "독수리", "매", "부엉이",
    "올빼미", "앵무새", "참새", "까마귀", "비둘기",
    "닭", "오리", "거위", "칠면조", "공작",
    "까치", "갈매기", "백조", "두루미", "타조",
    "꿀벌", "나비", "잠자리", "개미", "사마귀",
    "매미", "파리", "모기", "풍뎅이", "지렁이",
    "달팽이", "가재", "게", "새우", "문어",
    "오징어", "해파리", "불가사리", "말미잘", "고둥",
    "코뿔소", "하이에나", "몽구스", "너구리", "스컹크",
    "수달", "담비", "침팬지", "오랑우탄", "고릴라",
    "원숭이", "바다거북", "청둥오리", "말", "낙타"
  ];

  List<String> returnSubjectList(String subject) {
    if (subject == "food") {
      return foodList;
    } else if (subject == "plant") {
      return plantList;
    } else{
      return animalList;
    }
  }


}
