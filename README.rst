===================
CloudX 노드 사이징 도구
===================

CloudX 클러스터의 노드 수·사양을 산정하는 단일 페이지 웹 도구입니다.
`GitHub Pages`_ 로 호스팅하며, 페이지에는 **비밀번호 보호**가 걸려 있습니다.

.. _GitHub Pages: https://pages.github.com/


개요
====

- 순수 정적 **단일 HTML**(``index.html``) 입니다. (서버·빌드 과정이 필요 없음)
- 공개 URL 로 아무나 접근하지 못하도록 `StatiCrypt`_ 로 페이지 전체를
  **AES 로 암호화**합니다. 방문자는 열 때 비밀번호를 입력해야 하며,
  맞을 때만 브라우저에서 복호화되어 도구가 나타납니다.
- 비밀번호는 이 저장소 어디에도 들어 있지 않습니다.

.. _StatiCrypt: https://github.com/robinmoisson/staticrypt


파일 구성
=========

==================  ============================================================
파일                설명
==================  ============================================================
``index.html``      암호화본. **이것만 커밋·배포**되며 GitHub Pages 가 호스팅
``decrypt.sh``      ``index.html`` -> ``index.src.html`` 복구(비밀번호 필요)
``index.src.html``  평문 원본(편집용). ``.gitignore`` 로 **커밋 차단**
``encrypt.sh``      ``index.src.html`` -> ``index.html`` 재암호화
``.gitignore``      평문·임시물 커밋 차단
==================  ============================================================


요구 사항
=========

로컬에 **Docker** 만 있으면 됩니다(스크립트가 ``node:20-slim`` 컨테이너로
StatiCrypt 를 실행합니다 — 호스트에 Node.js 설치 불필요).

.. note::

   Docker/Node 는 **로컬에서 파일을 만들 때만** 쓰입니다. GitHub Pages 쪽에는
   결과물 ``index.html`` 정적 파일 하나만 올라가며, 서버 설정이 전혀 필요 없습니다.


편집과 배포
===========

1. 복호화합니다::

    ./decrypt.sh          # 비밀번호 입력 -> index.src.html 복구

2. 평문 원본을 편집합니다::

     vi index.src.html

3. 재암호화합니다::

     ./encrypt.sh          # 비밀번호 입력 -> index.html 로 암호화

3. 암호화본을 커밋·푸시하면 Pages 에 반영됩니다::

     git add index.html
     git commit -m "사이징 도구 갱신"
     git push


비밀번호 변경
=============

평문 원본(``index.src.html``)이 있는 상태에서 새 비밀번호로 다시 암호화하면 됩니다::

     ./encrypt.sh          # 새 비밀번호 입력
     git add index.html && git commit -m "비밀번호 변경" && git push
