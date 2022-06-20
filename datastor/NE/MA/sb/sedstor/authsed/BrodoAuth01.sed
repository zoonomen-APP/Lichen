#This runs in test sed, but when running sed -i BrodoAuth01.sed get error
#sed: -e expression #1, char 6: unterminated `s' command
# resolution, cp tmp.df df0606. == unresolved.
s/|Bennett, J. ; Brodo, Irwin M.$/|Bennett,J. ; Brodo,I.M./
s/|Brodo$/|Brodo,I.M./
s/|Brodo, Daniel C. ; Brodo, Irwin M.$/|Brodo,D.C. ; Brodo,I.M./
s/|Brodo, Fenja ; Brodo, Irwin M.$/|Brodo,F.,Ms. ; Brodo,I.M./
s/|Brodo, Fenja ; Brodo, Irwin M. ; Schumm, Felix$/|Brodo,F.,Ms. ; Brodo,I.M. ; Schumm,F./
s/|Brodo, Fenja ; Schumm, Felix ; Brodo, Irwin M.$/|Brodo,F.,Ms. Schumm,F. ; Brodo,I.M./
s/|Brodo, I.$/|Brodo,I.M./
s/|Brodo, I. M.$/|Brodo,I.M./
s/|Brodo, Irwin M$/|Brodo,I.M./
s/|Brodo, Irwin, M.$/|Brodo,I.M./
s/|Brodo, Irwin M. ; Anderson, Frances ; Jansen, Curtis ; Brendan, H. ; Fraker, Emily Jean$/|Brodo,I.M. ; Anderson,F.,Ms. ; Jansen,C. ; Brendan,H. ; Fraker,E.J.,Ms./
s/|Brodo, Irwin M. ; Bennett, J.$/|Brodo,I.M. ; Bennett,J./
s/|Brodo, Irwin M. ; Bennett, James$/|Brodo,I.M. ; Bennett,J./
s/|Brodo, Irwin M. ; Bennett, James ; Bennett, James$/|Brodo,I.M. ; Bennett,J./
s/|Brodo, Irwin M. ; Brodo, Fenja$/|Brodo,I.M. ; Brodo,F.,Ms./
s/|Brodo, Irwin M. ; Brodo, Fenja ; Coffey, Heather$/|Brodo,I.M. ; Brodo,F.,Ms. ; Coffey,H.,Ms./
s/|Brodo, Irwin M. ; Brodo, Fenja ; Schumm, Felix$/|Brodo,I.M. ; Brodo,F.,Ms. ; Schumm,F./
s/|Brodo, Irwin M. ; Brodo, Fenja ; Sharnoff, Sylvia D. ; Sharnoff, Steve$/|Brodo,I.M. ; Brodo,F.,Ms. ; Sharnoff,S./
s/|Brodo, Irwin M. ; Brodo, Irwin M.$/|Brodo,I.M./
s/|Brodo, Irwin M. ; Cole, Mariette ; Brodo, Fenja ; Hawksworth, D.L.$/|Brodo,I.M. ; Cole,M.,Ms. ; Fryday,A.M. ; Brodo,F.,Ms. ; Hawksworth,D./
s/|Brodo, Irwin M. ; Fryday, Alan M. ; Schaefer, Harold$/|Brodo,I.M. ; Fryday,A.M. ; Schaefer,H./
s/|Brodo, Irwin M. ; Fryday, Alan M. ; Schaefer, Harold ; Brodo, Irwin M. ; Fryday, Alan M. ; Schaefer, Harold$/|Brodo,I.M. ; Fryday,A.M. ; Schaefer,H./
s/|Brodo, Irwin M. ; Lutzoni, François ; Robitaille, Gilles$/|Brodo,I.M. ; Lutzoni,F. ; Robitaille,G./
s/|Brodo, Irwin M. ; Robitaille, Gilles ; Lutzoni, François$/|Brodo,I.M. ; Robataille,G. ; Lutzoni,F./
s/|Brodo, Irwin M. ; Schomer, Barbara ; Brodo, Fenja$/|Brodo,I.M. ; Schomer,B.,Ms. ; Brodo,F.,Ms./
s/|Brodo, Irwin M. ; Sharnoff, Steve ; Sharnoff, Sylvia D. ; Brodo, Fenja ; Buckley, Ann ; Hendrickson, Ted$/|Brodo,I.M. ; Sharnoff,S. ; Sharnoff,S.D,Ms. ; Brodo,F.,Ms. ; Buckley,A.,Ms. ; Hendrickson,T./
s/|Brodo, Irwin, M.; Bennett, James$/|Brodo,I.M. ; Bennett,J./
s/|Brodo, Irwin, M.; MacKeever, Fred$/|Brodo,I.M. ; MacKeever,F.C./
s/|Freebury, Colin E. ; Brodo, Irwin M.$/|Freebury,C.E. ; Brodo,I.M./
s/|Hawksworth, D.L. ; Brodo, Fenja ; Brodo, Irwin M. ; Cole, Mariette$/|Hawksworth,D.L. ; Brodo,F.,Ms. ; Brodo,I.M. ; Cole,M.,Ms./
s/|Hawksworth, D.L. ; Cole, Mariette ; Brodo, Fenja ; Brodo, Irwin M.$/|Hawksworth,D.L. ; Cole,M.,Ms. ; Brodo,F.,Ms. ; Brodo,I.M./
s/|I. Brodo$/|Brodo,I.M./
s/|I. Brodo & F. Mackeever$/|Brodo,I.M. ; MacKeever,F.C./
s/|I. Brodo & Mackeever$/|Brodo,I.M. ; MacKeever,F.C./
s/|I. M. Brodo$/|Brodo,I.M./
s/|I. M. Brodo & F. C. MacKeever$/|Brodo,I.M. ; MacKeever,F.C./
s/|I. M. Brodo & F. MacKeever$/|Brodo,I.M. ; MacKeever,F.C./
s/|I. M. Brodo & Fred MacKeever$/|Brodo,I.M. ; MacKeever,F.C./
s/|I.M. Brodo$/|Brodo,I.M./
s/|I.M. Brodo, A. Legault & S. Brisson$/|Brodo,I.M. ; Legaurlt,A. ; Brisson,S./
s/|I.M. Brodo, Steve Sharnoff, Ted Hendrickson$/|Brodo,I.M. ; Sharnoff,S. ; Hendrickson,T./
s/|Irwin Brodo$/|Brodo,I.M./
s/|Irwin M Brodo$/|Brodo,I.M./
s/|Irwin M. Brodo$/|Brodo,I.M./
s/|Irwin M Brodo; M Mackeever$/|Brodo,I.M. ; MacKeever,F.C./
s/|Smith, D. ; Brodo, Irwin M. ; Brodo, Fenja ; Sheldon, Mark$/|Smith,D. ; Brodo,I.M. ; Brodo,F.,Ms. ; Sheldon,M./
