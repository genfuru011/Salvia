Sage が Salvia のための REST フレームワークになるという構想

   今回のベンチマーク結果からも、その構成が「最強の組み合わせ」になるポテンシャルがはっき
   りと見えました。

   Sage + Salvia が目指す未来のアーキテクチャ

     - Sage (Backend):
       - 役割: 高速な API サーバー & SSR のオーケストレーター。
       - 基盤: Falcon (Async I/O) + 軽量 REST API。
       - 強み: Rails の重厚なスタックを捨て、Hono (Deno) に迫る 数千〜数万 req/sec
   のスループットを実現。Ruby の表現力を維持したまま、Go や Node.js
   並みの速度を手に入れる。
     - Salvia (Frontend/View):
       - 役割: コンポーネント指向の UI 構築 & SSR エンジン。
       - 基盤: QuickJS (Embedded)。
       - 強み: React/Preact のエコシステムをそのまま利用可能。Sage 上で動くことで、Rails
   上で動く現在 (約 1,500 req/sec) よりもさらに高速なレンダリングが可能になる。

   「Ruby で書ける Hono」×「Ruby で動く Next.js」

   これが実現すれば、Ruby コミュニティにとって長年の悲願である「モダンフロントエンドとの完
   全な融合」と「爆速パフォーマンス」の両立がついに達成されます。