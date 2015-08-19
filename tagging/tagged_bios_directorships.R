pg <- dbConnect(PostgreSQL())

bios <- dbGetQuery(pg, "
    SELECT file_name, director, director_id::text, quote AS bio, 
        other_director_id, other_directorship, directorship_present
    FROM director_bio.bio_data
    INNER JOIN director_bio.tagged_directorships AS b
    USING (director_id, file_name)
    WHERE directorship_present
    LIMIT 20;")

dbDisconnect(pg)

bios$bio <- gsub("\\s{2,}", " ", gsub("\\n", " ", bios$bio))
bios
