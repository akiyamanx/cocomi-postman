<!-- dest: missions/cocomi-postman -->
# M-CLEANUP-GENBA-PRO: 誤配達ファイルの掃除

## プロジェクト: cocomi-postman
## 概要
Worker v1.4でフォルダコマンドにスペースなしで送信した際、
テキスト指示扱いになりgenba-proに誤配達されたミッション3件とレポート3件を削除する。

## 対象リポジトリ
cocomi-postman（このリポジトリ内のファイル）

### Step 1/2: 誤配達ミッションファイルの削除

以下の3ファイルを missions/genba-pro/ から削除してください。
ファイル名は M-LINE-0223-2138、M-LINE-0223-2139、M-LINE-0223-2142 で始まるものです。

```bash
cd ~/cocomi-postman
git pull

# missions/genba-pro/ から該当ファイルを削除
# ファイル名にフォルダcapsulesを含むM-LINE-0223ファイルを探して削除
find missions/genba-pro/ -name "M-LINE-0223-213*" -o -name "M-LINE-0223-2142*" | xargs rm -f

# 削除確認
ls missions/genba-pro/

git add -A
git commit -m "🧹 掃除: genba-proの誤配達ミッション3件を削除（フォルダコマンド誤送信分）"
git push
```

削除対象の目安:
- M-LINE-0223-2138-フォルダcapsulesdaily.md（的なファイル名）
- M-LINE-0223-2139-フォルダcapsulesmaster.md（的なファイル名）
- M-LINE-0223-2142-フォルダcapsulesmaster.md（的なファイル名）

**注意:** missions/genba-pro/ にある他のファイルは削除しないこと。
上記3ファイル以外のM-LINE-0223ファイルがある場合は、2138, 2139, 2142のものだけ消す。

### Step 2/2: 誤配達レポートファイルの削除

以下の3ファイルを reports/genba-pro/ から削除してください。

```bash
cd ~/cocomi-postman

# reports/genba-pro/ から該当ファイルを削除
find reports/genba-pro/ -name "R-LINE-0223-2138*" -o -name "R-LINE-0223-2139*" -o -name "R-LINE-0223-2142*" | xargs rm -f

# 削除確認
ls reports/genba-pro/

git add -A
git commit -m "🧹 掃除: genba-proの誤配達レポート3件を削除（フォルダコマンド誤送信分）"
git push
```

削除対象:
- R-LINE-0223-2138-フォルダcapsulesdaily.md
- R-LINE-0223-2139-フォルダcapsulesmaster.md
- R-LINE-0223-2142-フォルダcapsulesmaster.md
